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
    timeout=120,
)
def check_hindsight_connectivity() -> dict:
    """Verify Hindsight connectivity and API accessibility from inside Modal sandbox."""
    import os
    import json
    import urllib.request
    import ssl

    hindsight_url = os.environ.get("HINDSIGHT_API_URL", "https://159.195.251.138.sslip.io:8888")
    api_key = os.environ.get("HINDSIGHT_API_KEY", "")

    ctx = ssl.create_default_context()
    # In case self-signed cert is used on sslip.io:
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    results = {
        "url": hindsight_url,
        "has_api_key": bool(api_key),
        "status": "unknown",
        "error": None,
    }

    try:
        req = urllib.request.Request(
            f"{hindsight_url.rstrip('/')}/health",
            headers={"Authorization": f"Bearer {api_key}"} if api_key else {},
        )
        with urllib.request.urlopen(req, timeout=10, context=ctx) as response:
            results["status"] = response.status
            results["response"] = response.read().decode("utf-8")[:500]
    except Exception as e:
        # Try root URL or banks endpoint if /health returns 404
        try:
            req = urllib.request.Request(
                f"{hindsight_url.rstrip('/')}/v1/banks",
                headers={"Authorization": f"Bearer {api_key}"} if api_key else {},
            )
            with urllib.request.urlopen(req, timeout=10, context=ctx) as response:
                results["status"] = response.status
                results["response"] = response.read().decode("utf-8")[:500]
        except Exception as e2:
            results["error"] = str(e2)

    return results


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
def main(
    prompt: str = "Hello Hermes! Can you introduce yourself and verify your memory and terminal tools?",
    check_hindsight: bool = True,
):
    """Test Hermes agent and Hindsight connectivity on Modal."""
    if check_hindsight:
        print("Checking Hindsight connectivity from Modal sandbox...")
        hs_res = check_hindsight_connectivity.remote()
        print(f"Hindsight connectivity result:\n{hs_res}\n")

    print(f"Sending prompt to Modal Hermes Worker: {prompt}")
    response = run_hermes_prompt.remote(prompt)
    print(f"Hermes response:\n{response}")
