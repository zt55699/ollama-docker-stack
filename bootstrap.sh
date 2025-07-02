#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
#  bootstrap.sh  (repo-aware version)
#  • assumes you’ve already git-cloned this repo
#  • only installs drivers, docker, and downloads GGUF if missing
#  • never overwrites Modelfile or compose files tracked in git
# ────────────────────────────────────────────────────────────────
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

### 0) Pre-flight
[[ -z "${HF_TOKEN:-}" ]] && {
  echo "❌  export HF_TOKEN=hf_xxx before running" ; exit 1 ; }

REPO_ROOT="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &>/dev/null && pwd )"
cd "$REPO_ROOT"

source .env          # pulls OLLAMA_MODEL, GGUF_FILE, etc.

### 1) Install NVIDIA driver + container toolkit (Ubuntu 22.04)
sudo apt-get update -qq
sudo apt-get install -y wget curl gnupg lsb-release docker.io docker-compose-plugin

if ! command -v nvidia-smi &>/dev/null ; then
  echo "🛠  Installing NVIDIA driver & toolkit …"
  distro=$(. /etc/os-release; echo ${ID}${VERSION_ID})
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo tee /usr/share/keyrings/nvidia-cont.gpg >/dev/null
  curl -s -L https://nvidia.github.io/libnvidia-container/$distro/libnvidia-container.list | \
    sed 's#deb #deb [signed-by=/usr/share/keyrings/nvidia-cont.gpg] #' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
  sudo apt-get update -qq
  sudo apt-get install -y nvidia-driver-555 nvidia-container-toolkit
  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart docker
fi

### 2) Download GGUF only if not present
if [[ ! -f "models/$GGUF_FILE" ]]; then
  echo "⬇️  Downloading $GGUF_FILE (~15 GB)…"
  docker run --rm -e HF_TOKEN="$HF_TOKEN" -v "$PWD/models":/data python:3.12-slim \
    bash -c "pip install -q 'huggingface_hub[cli]==0.23.4' && \
             huggingface-cli download $GGUF_REPO $GGUF_FILE \
             --token \$HF_TOKEN --local-dir /data --resume-download"
else
  echo "✔️  GGUF already present – skipping download"
fi

### 3) Start the stack
echo "🚀  Launching Docker services …"
docker compose pull ollama
docker compose up -d ollama

### 4) Register model if not yet created
if ! docker exec ollama ollama list | grep -q "$OLLAMA_MODEL" ; then
  echo "📝  Creating model inside Ollama …"
  docker exec -it ollama ollama create "$OLLAMA_MODEL" -f "/root/.ollama/models/Modelfile-${OLLAMA_MODEL}"
else
  echo "✔️  Model $OLLAMA_MODEL already exists"
fi

echo ""
echo "🎉  Ready!  Chat at  http://$(hostname -I | awk '{print $1}'):${HOST_PORT:-11434}/api/chat"
