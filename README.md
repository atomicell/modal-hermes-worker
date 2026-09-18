# modal-hermes-worker

Docker image and Modal deployment configuration for **Hermes Agent** based on `ghcr.io/omnigent-ai/omnigent-host:latest`.

This image is configured to run Hermes Agent identically to the host environment, specifically configured for:
- **LLM Inference**: OpenAI-compatible endpoint at `https://api.cheaperinference.com/v1` (default model: `glm-5.3-flash`).
- **Memory Integration**: Hindsight memory provider configured in `local_external` mode connecting to `https://159.195.251.138.sslip.io:8888`.
- **Public & Secure**: Zero hardcoded secrets/tokens; all authentication is injected via environment variables at runtime.

---

## Features & Configuration

1. **Base Image**: `ghcr.io/omnigent-ai/omnigent-host:latest` with Python 3.12, Node.js, and system utilities.
2. **Hermes Agent**: Installed from official repository with extras `[hindsight, firecrawl]`.
3. **Execution Environment**: Runs directly inside the sandbox container (`terminal.backend: local`) without nested Modal sub-sandboxes.
4. **Inference Provider**:
   - Provider: `custom` (OpenAI-compatible)
   - Base URL: `https://api.cheaperinference.com/v1`
   - Default Model: `glm-5.3-flash`
   - Discovered Model Catalog: Full CheaperInference models (GLM, Claude, GPT, DeepSeek, Qwen, Gemini, etc.)
   - API Key Variable: `HERMES_CUSTOM_API_CHEAPERINFERENCE_COM_API_KEY` (or `CHEAPERINFERENCE_API_KEY`)
4. **Hindsight Memory Provider**:
   - Provider: `hindsight`
   - Mode: `local_external`
   - API URL: `https://159.195.251.138.sslip.io:8888`
   - Bank ID: `hermes`
   - Recall Budget: `mid`
   - Recall Types: `observation,world,experience`
   - API Key Variable: `HINDSIGHT_API_KEY`
5. **Prompt & Soul**: Hermes Agent soul configured in `SOUL.md`.

---

## Environment Variables

| Variable | Description | Required |
| --- | --- | --- |
| `HERMES_CUSTOM_API_CHEAPERINFERENCE_COM_API_KEY` | API key for CheaperInference endpoint | Yes |
| `CHEAPERINFERENCE_API_KEY` | Alias for CheaperInference API key | Optional |
| `HINDSIGHT_API_KEY` | API key for Hindsight memory server | Yes (if memory enabled) |
| `HINDSIGHT_API_URL` | Override Hindsight memory server URL | Optional |
| `FIRECRAWL_API_KEY` | API key for Firecrawl web search backend | Optional |

---

## Building and Running with Docker

### Pull Pre-built Image from GHCR
```bash
docker pull ghcr.io/atomicell/modal-hermes-worker:latest
```

### Build Image Locally
```bash
docker build -t modal-hermes-worker:latest .
```

### Run Hermes Agent CLI Interactively
```bash
docker run -it --rm \
  -e HERMES_CUSTOM_API_CHEAPERINFERENCE_COM_API_KEY="your-cheaperinference-api-key" \
  -e HINDSIGHT_API_KEY="your-hindsight-api-key" \
  ghcr.io/atomicell/modal-hermes-worker:latest
```

### Run a Single Hermes Command
```bash
docker run --rm \
  -e HERMES_CUSTOM_API_CHEAPERINFERENCE_COM_API_KEY="your-cheaperinference-api-key" \
  -e HINDSIGHT_API_KEY="your-hindsight-api-key" \
  ghcr.io/atomicell/modal-hermes-worker:latest hermes chat -q "What tools do you have available?"
```

---

## Running on Modal

The repository includes `modal_app.py` for deploying and running Hermes Agent on Modal.

### 1. Set Up Modal Secrets
Create a secret containing your API keys:
```bash
modal secret create hermes-secrets \
  HERMES_CUSTOM_API_CHEAPERINFERENCE_COM_API_KEY="your-cheaperinference-api-key" \
  HINDSIGHT_API_KEY="your-hindsight-api-key"
```

### 2. Test Locally via Modal
```bash
modal run modal_app.py --prompt "Explain quantum computing in two sentences."
```

### 3. Deploy Worker/Gateway to Modal
```bash
modal deploy modal_app.py
```

---

## GitHub Integration & Repository Setup

Remote repository:
```bash
git remote add origin git@github.com:atomicell/modal-hermes-worker.git
```

SSH Authentication:
To authenticate with GitHub using the key pair in `./ssh/github`:
```bash
# Configure Git to use the dedicated SSH key
git config core.sshCommand "ssh -i ~/.ssh/github -o IdentitiesOnly=yes"

# Push changes
git push -u origin main
```
