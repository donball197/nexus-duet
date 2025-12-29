# Nexus-Duet: Autonomous Hybrid AI Pipeline 🚀

**Nexus-Duet** is a fully autonomous DevOps AI agent designed to operate as a self-healing infrastructure engineer. It combines **local-first privacy** (Ollama-powered LLMs) with **cloud-grade reasoning** to manage builds, deployments, diagnostics, and recovery without human intervention.

| Service | Status | Link |
| :--- | :---: | :--- |
| **Database** | ![DB](https://img.shields.io/badge/PostgreSQL-Healthy-success?logo=postgresql) | [Backups](./backups) |
| **Local AI** | ![Ollama](https://img.shields.io/badge/Ollama-Online-blue?logo=ollama) | [Models](https://ollama.com) |
| **System API** | ![API](https://img.shields.io/badge/Backend-Active-brightgreen?logo=rust) | [Health Check](./health_check.sh) |
| **Tasks Solved** | ![Tasks](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/donball197/c2551982b6c936746863001859942a49/raw/athena_tasks.json) | [Live Stats](https://gist.github.com/donball197) |

## 🏗️ System Architecture

flowchart TD
    Developer[Developer / CLI]
    API[Nexus-Duet Core API]
    LocalLLM[Local LLMs - Ollama]
    CloudAI[Cloud AI - Gemini / OpenAI]
    DB[(PostgreSQL Database)]
    FS[Local Filesystem]
    Gist[GitHub Gists / Badges]

    Developer -->|Commands| API
    API -->|Inference| LocalLLM
    API -->|Escalation| CloudAI
    API -->|State| DB
    API -->|Read / Write| FS
    API -->|Status Updates| Gist
