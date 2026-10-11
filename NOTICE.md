# NOTICE: JupyterLab 4 Data Science Workstation template

## Software used

| Component | Source | License | How it is used |
|---|---|---|---|
| Jupyter Docker Stacks `scipy-notebook` | `quay.io/jupyter/scipy-notebook:2026-10-05`, https://github.com/jupyter/docker-stacks | BSD-3-Clause, Copyright (c) 2001-2015 IPython Development Team, (c) 2015- Jupyter Development Team | Base image (`FROM`), used unmodified; its `start.sh` hook mechanism (`before-notebook.d`) and documented options (`RESTARTABLE`, `GRANT_SUDO`, `NB_USER`/`NB_UID`) are used as designed |
| JupyterLab, Jupyter Server, Notebook | in the base image | BSD-3-Clause (Project Jupyter) | Run unmodified |
| Python packages (pandas, NumPy, SciPy, scikit-learn, matplotlib, ...) | in the base image (conda-forge) | various open-source licenses | Run unmodified |

Product names belong to their owners. This is a community template, not affiliated with Project Jupyter.

## Upstream files and docs checked (2026-10-11)

- `jupyter/docker-stacks` commit `f2974d177c3cc1d2afc1522e0461c9faa07eb8a2` (the source of the `2026-10-05` image): `images/docker-stacks-foundation/Dockerfile`, `start.sh`, `run-hooks.sh`, `images/base-notebook/Dockerfile`, `jupyter_server_config.py`, `start-notebook.py`, `docker_healthcheck.py` (uses `GET /api`), `images/minimal-notebook/Dockerfile`, `images/scipy-notebook/Dockerfile`.
- quay.io tag list for `jupyter/scipy-notebook` (date tags, `lab-4.6.4`, `python-3.13.15`, `ubuntu-26.04`).
- Inside the image: `jupyter --version` (JupyterLab 4.6.4, Jupyter Server 2.21.1), `jupyter_server.base.handlers.APIVersionHandler` (`@allow_unauthenticated`), `PasswordIdentityProvider` traits, JupyterLab `@jupyterlab/apputils-extension:notification` settings schema, `jupyter_core.paths.jupyter_config_path()` order.

## Market templates and repositories reviewed

| Template / repo | License | Use |
|---|---|---|
| `WpjhAn` "JupyterLab" (image-only template) | n/a (template config) | Base for the service concept and variables (`JUPYTER_PASSWORD`, `RESTARTABLE`, port 8888). No files exist to copy; configuration rewritten. |
| `JEeFjP` / `jmitchel3/jupyter-container` | none (all rights reserved) | Read only, nothing copied. |
| `jupyter-notebook-and-jupyterlab-cloud-de` (image-only template) | n/a | Reviewed, nothing taken. |

All files in this package (`Dockerfile`, `20-railway-setup.sh`, `railway_jupyter_server_config.py`, `overrides.json` and the docs) were written for this template. No README text from other templates was reused.
