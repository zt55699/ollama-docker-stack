# Gemma-3-27B Abliterated on Ollama 🦙 (One-Click Docker Stack)

Run Google’s **Gemma-3-27B-it-abliterated** (4-bit) entirely on your own GPU, stream
tokens to any device, and swap in new models with one env change.

---

## ✨ Features

|                                 | This stack |
|---------------------------------|------------|
| **Self-hosted, offline**        | Yes – weights stay on your GPU |
| **One-click bootstrap**         | `bootstrap.sh` installs driver → Docker → pulls model |
| **Token streaming**             | Standard Ollama `/api/chat` endpoint |
| **Model hot-swap**              | Edit `.env` → `docker compose up -d` |
| **GPU tuning knobs**            | `NUM_GPU`, `NUM_CTX` in `.env` |
| **Metrics ready** _(optional)_  | NVIDIA DCGM exporter on port **:9400** |
| **Exposable**                   | Works with Cloudflare Tunnel / Tailscale |

---

## 1. Requirements

| Item | Minimum |
|------|---------|
| OS   | Ubuntu 22.04 LTS / WSL2 / any Linux with **CUDA** card |
| GPU  | ≥ 16 GB VRAM (NVIDIA 3090, 4090, RTX 5080, A5000, L4…) |
| Driver | **555.xx** or newer |
| Disk | ≈ 20 GB (free for GGUF + Docker layers) |
| Hugging Face account | *Read* token only |

---

## 2. Quick Start 🚀

```bash
# 0) SSH into a fresh GPU VM (or use your desktop)
sudo apt-get update && sudo apt-get install -y git curl

# 1) Clone this repo
git clone https://github.com/<your-user>/gemma27b-ollama-stack.git
cd gemma27b-ollama-stack

# 2) Copy env template and set your HuggingFace token
cp .env.example .env
nano .env            # set HF_TOKEN  +  tweak NUM_GPU / NUM_CTX if needed

# 3) Run the bootstrap (installs driver, docker, pulls model, starts stack)
chmod +x bootstrap.sh
./bootstrap.sh
```
🔄 Daily-driver commands — bring the stack back up in seconds
Where you are:
you already ran bootstrap.sh, which created
~/gemma27 (or C:\LLM\gemma27 on WSL/Windows) containing
docker-compose.yml, Modelfile, and the downloaded GGUF.

Situation	What to type	What it does
Start after a fresh reboot (compose was already configured)	bash cd ~/gemma27 # go to the folder docker compose up -d # start Ollama + exporter	Reads the existing containers/volumes and launches them in the background.
Stop the service	bash docker compose down # stops & frees GPU	Leaves volumes (GGUF, cache) intact.
Restart because you tweaked .env or Modelfile	bash docker compose down \ && docker compose up -d ollama	Ensures environment-variable changes are applied.
Re-register model after editing Modelfile	bash docker exec -it ollama \ ollama create $OLLAMA_MODEL \ -f /root/.ollama/models/Modelfile	Re-reads the Modelfile without rebuilding the container.
Update Ollama to newest build	bash docker compose pull ollama docker compose up -d ollama	Pulls the latest image, restarts only that service.


Minimal repo tree

gemma27b-ollama-stack/
├─ bootstrap.sh
├─ docker-compose.yml
├─ .env.example
├─ models/
│   ├─ Modelfile-gemma27b-q4s
│   ├─ Modelfile-gemma27b-q3m
│   └─ (GGUF files land here at deploy time)
└─ docs/
Clone repo → edit .env → ```./bootstrap.sh```.

Future boots: ```docker compose up -d.```