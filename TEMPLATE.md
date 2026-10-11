# JupyterLab 4 Data Science Workstation: Railway template spec

## Listing

| Field | Value |
|---|---|
| Name | **JupyterLab 4 Data Science Workstation** (LISTINGS_ROUND2 base name with the JupyterLab major inserted after the software name) |
| Description | Notebooks with a Python data stack, persistent storage and password login. (74 chars, unchanged) |
| Category | AI/ML |
| Tags | jupyter, jupyterlab, notebook, python, data-science, pandas, scikit-learn, machine-learning |
| Icon | `https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/jupyter.svg` (200 OK) |

The description is delivered as written: the image is the official Jupyter Docker Stacks `scipy-notebook` (pandas, NumPy, SciPy, scikit-learn, matplotlib, seaborn, statsmodels, Dask, Numba, SQLAlchemy, ...), the whole home directory is a Railway volume, and the UI asks for a generated password.

## Base market template

- **Base: `WpjhAn` "JupyterLab"** (310 active / 596 total, created 2023-03). Kept what users pick it for: the official `quay.io/jupyter/scipy-notebook` image, a generated `JUPYTER_PASSWORD`, `RESTARTABLE=yes`, port 8888 and a volume. Problems fixed: unpinned `scipy-notebook` (implicit `latest`), the volume only covers `/home/jovyan/work` (dotfiles, pip `--user` packages, kernels, JupyterLab settings and the login cookie secret are lost on every redeploy), a long `startCommand` that runs `jupyter server password` and `chown -R` over the whole volume on every start (slow on large volumes, and writes the hash to the volume where a stale value can override a changed variable), the plain password visible to every notebook (`%env`) and terminal, the whole container forced to root via `RAILWAY_RUN_UID=0`, healthcheck on `/login` (an HTML page) instead of the API.
- `JEeFjP` "Jupyter Container - Interactive Python" (64 active, repo `jmitchel3/jupyter-container`, no license: read only, nothing copied). Idea noted, not adopted: installing packages from a variable at build time. Here pip installs persist on the volume instead.
- `jupyter-notebook-and-jupyterlab-cloud-de` (17 active): unpinned `jupyter/all-spark-notebook` from the deprecated Docker Hub namespace (Docker Stacks moved to quay.io in 2023), `pip install` on every start, no healthcheck. Nothing taken.
- `_upstream/jmitchel3__jupyter-container`: no license, read only, nothing copied.

## Pinned versions

| Component | Source | Version | Released | Checked |
|---|---|---|---|---|
| Base image | `quay.io/jupyter/scipy-notebook:2026-10-05` (Docker Stacks commit `f2974d177c3c`) | weekly build 2026-10-05 | 2026-10-05 | 2026-10-11 |
| JupyterLab | in image | 4.6.4 | in image | 2026-10-11 |
| Jupyter Server | in image | 2.21.1 | in image | 2026-10-11 |
| Notebook | in image | 7.6.3 | in image | 2026-10-11 |
| Python | in image (conda-forge) | 3.13.15 | in image | 2026-10-11 |
| OS | in image | Ubuntu 26.04 | in image | 2026-10-11 |

Docker Stacks rebuilds every image weekly and moves `latest`, `lab-4.6.4`, `python-3.13` to each new build. The date tag (`2026-10-05`) is the immutable reference for one build, which is what upstream recommends pinning. Upgrade: change `ARG BASE_IMAGE` in `services/jupyterlab/Dockerfile` to a newer date tag from https://quay.io/repository/jupyter/scipy-notebook?tab=tags and redeploy.

Note: Docker Stacks moved from Ubuntu 24.04 to 26.04 in the 2026-10-05 build. The template was built and run locally on that build (see verification below).

## Architecture

```
 Browser ── HTTPS (Railway edge) ──► :8888 Jupyter Server (JupyterLab 4, Notebook 7)
 IDE / scripts ── Authorization: token ──┘        │  /api = healthcheck (unauthenticated version JSON)
                                                  │
  ┌───────────────────────────────────────────────┴──────────────┐
  │ JupyterLab service (Dockerfile in services/jupyterlab)        │
  │ tini → start.sh (root): before-notebook.d/20-railway-setup.sh │
  │   seed + chown volume, hash password, drop secrets from env    │
  │ → sudo -u jovyan run-one-constantly jupyter lab                │
  │ kernels: python3 (conda base) + any env in ~/.conda/envs       │
  │ volume /home/jovyan (notebooks, ~/.local, ~/.conda, settings)  │
  └────────────────────────────────────────────────────────────────┘
```

One service on purpose: a single-user notebook server has no database, worker or cache in its upstream stack. Users who need a database attach one from Railway and connect over the private network.

## Services

### JupyterLab

| Setting | Value |
|---|---|
| Source | repo `baranberkay96/jupyterlab-railway`, root `/services/jupyterlab` (Dockerfile) |
| Start command | image default (`tini -g -- start.sh start-notebook.py`) |
| Healthcheck | `/api` (Jupyter Server version endpoint, unauthenticated, 200 once the server is up), timeout 300 s |
| Public domain | yes, target port 8888 |
| Volume | `/home/jovyan` |
| Restart policy | ON_FAILURE, 10 retries (plus `RESTARTABLE=yes` inside the container) |
| Replicas | 1 (volume-backed, single user) |

Files in `services/jupyterlab/`:

- `Dockerfile`: `FROM quay.io/jupyter/scipy-notebook:2026-10-05`, adds the files below, snapshots the image home to `/opt/jovyan-home-seed`, adds `~/.conda/envs` as the first conda `envs_dirs`, appends `~/.local/bin` to `PATH`, sets `TINI_SUBREAPER`, runs as root so `start.sh` can prepare the volume and then drop to `jovyan`.
- `20-railway-setup.sh` (start hook, sourced by Docker Stacks `start.sh` as root): removes the empty `lost+found`, seeds an empty volume once from the image home (marker `~/.railway-home-seeded`), `chown` (non-recursive) of the volume root to `jovyan:users`, hashes `JUPYTER_PASSWORD` with argon2 into `/etc/jupyter/railway/hashed_password` (mode 0640, group `users`), stores `JUPYTER_TOKEN` the same way, then unsets both so Jupyter, kernels and terminals never see them.
- `railway_jupyter_server_config.py` → `/usr/local/etc/jupyter/jupyter_server_config.py`: `port=$PORT`, `trust_xheaders`, terminals on, password and token from the hook files (with an env fallback when not started as root), `allow_password_change=False`, empty token never disables auth, optional kernel culling.
- `overrides.json` → JupyterLab settings overrides: no news feed and no update-check requests.

Variables (descriptions in `template.json`):

| Variable | Default | Notes |
|---|---|---|
| `PORT` | `8888` | Healthcheck and domain target. |
| `JUPYTER_PASSWORD` | `${{secret(24)}}` | Web login. Empty = token-only login. |
| `JUPYTER_TOKEN` | `${{secret(48, hex)}}` | For VS Code, PyCharm, `jupyter` CLI clients and REST calls. Empty = random token printed in the deploy logs (the server is never unauthenticated). |
| `RESTARTABLE` | `yes` | Docker Stacks option: `run-one-constantly`. |
| `PIP_USER` | `1` | `pip install` / `%pip install` go to `~/.local` (persistent). |
| `JUPYTER_KERNEL_CULL_IDLE_TIMEOUT` | `0` | Seconds; 0 = off. |
| `GRANT_SUDO` | `no` | Docker Stacks option. |
| `TZ` | `UTC` | |
| `RAILWAY_DEPLOYMENT_DRAINING_SECONDS` | `30` | Clean kernel shutdown on redeploy. |

No required inputs.

## First login

1. Open the public URL. Jupyter shows a login page.
2. Paste `JUPYTER_PASSWORD` from the service's Variables tab.
3. Work in `~/work` or anywhere under `/home/jovyan`; everything there persists.
4. IDE: in VS Code ("Select Kernel" → "Existing Jupyter Server") use `https://{your-domain}/?token={JUPYTER_TOKEN}`.

## Improvements over market templates

1. **Whole home directory persists** (`/home/jovyan`), not only `~/work`: pip `--user` packages, conda environments (`~/.conda/envs` is first in `envs_dirs`), registered kernels, JupyterLab settings and workspaces, git config, SSH keys and the cookie secret (logins survive redeploys).
2. **Pinned build** of the official image (date tag) instead of floating `latest`; one-line upgrade.
3. **Password never exposed**: hashed in a root start hook; neither the Jupyter process nor kernels or terminals carry `JUPYTER_PASSWORD` / `JUPYTER_TOKEN` (checked in `/proc/<pid>/environ`). `%env` in a shared notebook cannot leak it.
4. **Token for tools**: generated API token for IDEs and automation; an empty value can never open the server.
5. **Fast restarts**: no recursive `chown` on every start; the volume is seeded once.
6. **Correct healthcheck** (`/api`) and `PORT`, proxy headers trusted (HTTPS redirects and secure cookies behind Railway's edge).
7. **Optional kernel culling** to cut RAM cost of forgotten kernels, `GRANT_SUDO` switch, no JupyterLab news/update calls.
8. Container no longer forced to root for Jupyter itself: root is used only for the start hook, Jupyter runs as `jovyan` (uid 1000).

## Resource estimate

Railway prices: RAM $10/GB-month, vCPU $20/vCPU-month, volume $0.15/GB-month.

| Service | Idle RAM / CPU | Typical RAM / CPU | Notes |
|---|---|---|---|
| JupyterLab | 0.15 GB / 0.01 vCPU (measured ~110 MB server, ~160 MB with one idle kernel) | 2 GB / 0.3 vCPU avg | Each kernel holds its data in RAM; pandas/scikit-learn work on a few GB of data needs 2-6 GB peaks |
| Volume `/home/jovyan` | 1 GB | 5-10 GB | datasets, conda envs (~1-2 GB each), pip packages |

Estimated monthly cost: **idle ≈ $2**, **typical ≈ $28** (2 GB × $10 + 0.3 vCPU × $20 + 10 GB × $0.15 ≈ $27.5). Heavy ML work scales with RAM.

Minimum plan: **Trial** works for light notebooks (1 GB RAM per service). **Hobby** recommended for real data work; Hobby's 5 GB volume cap limits datasets and extra conda environments; Pro for larger volumes.

## Verification checklist

Local (done 2026-10-11, `docker build --platform linux/amd64` + `docker run --init` with a root-owned volume containing `lost+found`): build OK; `/api` 200 `{"version": "2.21.1"}`; `/lab` 302 to `/login`; password login 302 → `/`; wrong password 401; token header 200, wrong token 403; volume seeded and owned by `jovyan:users`, `lost+found` removed; Jupyter process environment without `JUPYTER_PASSWORD`/`JUPYTER_TOKEN`; `pip install` landed in `~/.local` and survived a container restart; `conda config --show envs_dirs` lists `~/.conda/envs` first; with both credentials empty `/api/status` still returns 403.

On first Railway deploy:

- [ ] Build succeeds; deploy healthy on `/api`.
- [ ] Public URL shows the login page; `JUPYTER_PASSWORD` logs in; a wrong password is refused.
- [ ] `curl -H "Authorization: token {JUPYTER_TOKEN}" https://{domain}/api/status` returns 200.
- [ ] Open a terminal (File → New → Terminal) and a Python notebook; `import pandas, sklearn, matplotlib` works; `%env` shows no `JUPYTER_PASSWORD`.
- [ ] Persistence: create `~/work/test.ipynb`, `%pip install tabulate`, `mamba create -n demo -y python=3.12 ipykernel && ~/.conda/envs/demo/bin/python -m ipykernel install --user --name demo`; redeploy; the notebook, `import tabulate` and the `demo` kernel are still there and you are still logged in.
- [ ] File → Shut Down: Jupyter comes back by itself within seconds (RESTARTABLE).

## Open questions

- Railway's handling of an image whose `USER` is root plus Docker Stacks' `sudo` drop was verified locally only; the market base uses `RAILWAY_RUN_UID=0` for the same effect, so it is expected to work.
- `tini` is not PID 1 on Railway (podman-init is). `TINI_SUBREAPER` is set so it still reaps children; verify no tini warning in deploy logs.
- Hobby volume cap (5 GB) is taken from STANDARD.md and may change.
