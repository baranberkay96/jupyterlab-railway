# Deploy and Host JupyterLab with Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/jupyterlab-4-data-science-workstation?referralCode=20H68q)

JupyterLab 4 in your browser with a ready Python data stack: pandas, NumPy, SciPy, scikit-learn, matplotlib, seaborn, statsmodels, Dask and more. Your notebooks, installed packages, conda environments and settings live on a persistent volume, and the server is protected by a generated password and API token.

## About Hosting JupyterLab

A notebook server needs more than a running container. It needs storage that survives redeploys, authentication that is on from the first request, and a way to add packages without rebuilding the image. This community template runs the official Jupyter Docker Stacks `scipy-notebook` image at a pinned weekly build, mounts the whole `/home/jovyan` directory on a Railway volume, and hashes the login password at start so it never appears inside notebooks or terminals. `pip install` and new conda environments go to the volume, so they are still there after an upgrade. Jupyter restarts itself inside the container if you shut it down from the menu.

## Common Use Cases

- Exploratory data analysis and visualisation with pandas, matplotlib, seaborn and Altair
- Training and evaluating scikit-learn and statsmodels models on data too big for a laptop session
- Querying databases on your Railway private network from notebooks (SQLAlchemy included)
- A shared, always-on scratchpad for scripts, cron-like experiments and teaching
- A remote Jupyter kernel for VS Code or PyCharm

## Dependencies for JupyterLab Hosting

- A Railway volume mounted at `/home/jovyan` (included)
- No external services or API keys are required

### Deployment Dependencies

- Jupyter Docker Stacks: https://jupyter-docker-stacks.readthedocs.io/
- scipy-notebook image tags: https://quay.io/repository/jupyter/scipy-notebook?tab=tags
- JupyterLab documentation: https://jupyterlab.readthedocs.io/
- Jupyter Server security (passwords and tokens): https://jupyter-server.readthedocs.io/en/latest/operators/security.html

### Implementation Details

| Service | Source | Purpose |
|---|---|---|
| JupyterLab | Dockerfile based on `quay.io/jupyter/scipy-notebook:2026-10-05` (JupyterLab 4.6.4, Python 3.13) | Web UI and kernels on port 8888, healthcheck `/api`, volume at `/home/jovyan` |

**First login**

1. Open the service URL and enter the value of `JUPYTER_PASSWORD` from the service's Variables tab.
2. Keep your work under `/home/jovyan` (for example `~/work`); everything there persists.
3. To connect an IDE, use `https://{your-domain}/?token={JUPYTER_TOKEN}` as the existing Jupyter server URL. Scripts can send the header `Authorization: token {JUPYTER_TOKEN}`.

**Installing packages**: `%pip install {package}` in a notebook or `pip install {package}` in a terminal installs into `~/.local` on the volume (`PIP_USER=1`). For separate environments run `mamba create -n {name} python=3.12 ipykernel`, then `~/.conda/envs/{name}/bin/python -m ipykernel install --user --name {name}`; both the environment and the kernel persist. `GRANT_SUDO=yes` enables `sudo apt-get`, but system packages reset on redeploy.

**Saving memory**: each open kernel keeps its data in RAM. Set `JUPYTER_KERNEL_CULL_IDLE_TIMEOUT` (seconds) to shut down idle kernels automatically.

**Scaling**: this is a single-user server, so keep one replica. Railway grows RAM and CPU vertically up to your plan limit. For a team, deploy one instance per person.

**Pinning and upgrades**: the base image is set by `ARG BASE_IMAGE` in `services/jupyterlab/Dockerfile`. Docker Stacks publishes a new date tag every week; change the tag and redeploy. Packages in `~/.local` are tied to the Python minor version, so after a Python upgrade reinstall them.

### Why Deploy JupyterLab on Railway?

Railway gives the notebook server an HTTPS URL, a persistent volume and private networking to your databases without any server administration. You pay for the RAM and CPU your kernels actually use, and you can resize or upgrade the image in minutes.
