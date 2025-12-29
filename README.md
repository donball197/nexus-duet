| Service | Status | Link |
| :--- | :---: | :--- |
| **Database** | ![DB](https://img.shields.io/badge/PostgreSQL-Healthy-success?logo=postgresql) | [Backups](./backups) |
| **Local AI** | ![Ollama](https://img.shields.io/badge/Ollama-Online-blue?logo=ollama) | [Models](https://ollama.com) |
| **System API** | ![API](https://img.shields.io/badge/Backend-Active-brightgreen?logo=rust) | [Health Check](./health_check.sh) |
# Nexus-Duet: Autonomous Hybrid AI Pipeline 🚀

**Nexus-Duet** is an intelligent DevOps agent that acts as a "Self-Healing" infrastructure engineer. It utilizes a **Hybrid AI Architecture** to combine the privacy of local LLMs with the reasoning power of Cloud AI.

![Status](https://img.shields.io/badge/Status-Operational-brightgreen)
![Tech](https://img.shields.io/badge/Stack-Rust%20%7C%20Docker%20%7C%20PostgreSQL-blue)
![AI](https://img.shields.io/badge/AI-Gemma%203%20%2B%20Gemini%203%20Flash-orange)

## 🧠 The Architecture
Nexus-Duet uses a **Smart Router** to orchestrate tasks between two brains:

1. **Tier 1: Local Mechanic (Gemma 3 - 1B)**
    * **Role:** Handles sensitive logs, bash scripting, and error patching.
    * **Cost:** $0 (Runs locally on Edge hardware).
    * **Privacy:** 100% Offline capability.

2. **Tier 2: Cloud Architect (Google Gemini 3 Flash)**
    * **Role:** Complex reasoning, architecture, and advanced problem solving.
    * **Performance:** High-level reasoning model.

## ⚡ Key Features
* **Self-Healing Pipeline:** Detects git updates and rebuilds backend.
* **Autonomous Log Analysis:** Reads logs and generates fix scripts.
* **Custom Training:** Integrated Colab workflow for fine-tuning.

## 🛠️ Installation
git clone https://github.com/donball197/nexus-duet.git
docker-compose up -d

---
*Built by **DonBall197**.*

## 🛡️ Security & Secret Management
This project follows industry-standard security practices for protecting sensitive credentials:

* **Environment Separation**: API keys and database credentials are never hardcoded in the source code.
* **Secret Masking**: All sensitive data is stored in a local-only `athena.env` file which is explicitly ignored by version control via `.gitignore`.
* **Key Rotation**: The architecture supports rapid key rotation and revocation via Google AI Studio and Docker environment injection.
* **Container Isolation**: Credentials are injected into the backend container at runtime using the `env_file` directive, ensuring secrets stay out of Docker image layers.
