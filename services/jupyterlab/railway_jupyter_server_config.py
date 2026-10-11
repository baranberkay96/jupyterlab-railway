# Jupyter Server settings for the Railway template.
#
# Loaded after /etc/jupyter/jupyter_server_config.py (Docker Stacks defaults:
# listen on all IPv4/IPv6 interfaces, no browser) and before
# ~/.jupyter/jupyter_server_config.py, so anything set here can still be
# overridden per user from the volume.
import os
from pathlib import Path

c = get_config()  # noqa: F821  (provided by traitlets when the file is loaded)

SECRETS_DIR = Path("/etc/jupyter/railway")


def _read_secret(name: str) -> str:
    """Return a value prepared by the start hook, or an empty string."""
    try:
        return (SECRETS_DIR / name).read_text(encoding="utf-8").strip()
    except OSError:
        return ""


# Railway routes traffic and healthchecks to $PORT.
c.ServerApp.port = int(os.environ.get("PORT") or os.environ.get("JUPYTER_PORT") or 8888)

# TLS ends at Railway's edge; trust X-Forwarded-* so redirects, cookies and
# client IPs reflect the public HTTPS request.
c.ServerApp.trust_xheaders = True

# Browser terminals (jupyter-server-terminals) stay on.
c.ServerApp.terminals_enabled = True

# Login password: JUPYTER_PASSWORD, hashed by the start hook (argon2). The
# login page must not offer to replace it with a different password.
hashed_password = _read_secret("hashed_password")
if not hashed_password and os.environ.get("JUPYTER_PASSWORD"):
    # Container not started as root (hook could not write the file): hash here.
    from jupyter_server.auth import passwd

    hashed_password = passwd(os.environ["JUPYTER_PASSWORD"])
if hashed_password:
    c.PasswordIdentityProvider.hashed_password = hashed_password
c.PasswordIdentityProvider.allow_password_change = False

# API token: JUPYTER_TOKEN, for IDEs and scripts (Authorization: token ...).
token = _read_secret("token") or os.environ.get("JUPYTER_TOKEN", "")
if token:
    c.IdentityProvider.token = token
elif "JUPYTER_TOKEN" in os.environ:
    # An empty JUPYTER_TOKEN would switch token auth off. Drop it so Jupyter
    # generates a random token instead and the server is never left open.
    del os.environ["JUPYTER_TOKEN"]

# Optional: shut down kernels that have been idle for N seconds to free RAM.
cull_after = int(os.environ.get("JUPYTER_KERNEL_CULL_IDLE_TIMEOUT") or 0)
if cull_after > 0:
    c.MappingKernelManager.cull_idle_timeout = cull_after
    c.MappingKernelManager.cull_interval = 60
    c.MappingKernelManager.cull_connected = False
