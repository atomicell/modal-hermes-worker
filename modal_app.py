"""Modal deployment for Hermes Worker.

Runs Hermes Agent containerized on Modal with GPU/CPU resources,
connected to CheaperInference (OpenAI-compatible) and Hindsight memory.
"""

import modal

# Define Modal App
app = modal.App("hermes-worker")

# Define image from Dockerfile or public registry
# To build directly from local Dockerfile:
hermes_image = modal.Image.from_dockerfile("Dockerfile")

# Secrets for API keys (never hardcoded)
# Create in Modal dashboard or via CLI: `modal secret create omnigent-llm CHEAPERINFERENCE_API_KEY=... HINDSIGHT_API_KEY=...`
hermes_secrets = modal.Secret.from_name("omnigent-llm")


@app.function(
    image=hermes_image,
    secrets=[hermes_secrets],
    timeout=600,
)
def run_hermes_prompt(prompt: str) -> str:
    """Run a one-off Hermes prompt/task."""
    import subprocess

    result = subprocess.run(
        ["hermes", "chat", "-q", prompt],
        capture_output=True,
        text=True,
    )
    return result.stdout or result.stderr


@app.function(
    image=hermes_image,
    secrets=[hermes_secrets],
    timeout=3600,
)
def run_gateway():
    """Run Hermes messaging gateway on Modal."""
    import subprocess

    subprocess.run(["hermes", "gateway"])


@app.local_entrypoint()
def main(prompt: str = "Hello Hermes, please introduce yourself."):
    """Test Hermes agent on Modal."""
    print(f"Sending prompt to Modal Hermes Worker: {prompt}")
    response = run_hermes_prompt.remote(prompt)
    print(f"Hermes response:\n{response}")
