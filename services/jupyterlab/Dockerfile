# JupyterLab 4 data-science workstation for Railway.
#
# Base: the official Jupyter Docker Stacks scipy-notebook image. The date tag is
# one weekly build of the stack (JupyterLab 4.6.4, Python 3.13, Ubuntu 26.04);
# upgrade by changing BASE_IMAGE to a newer date tag and redeploying.
ARG BASE_IMAGE=quay.io/jupyter/scipy-notebook:2026-10-05
FROM ${BASE_IMAGE}

USER root

# Railway defaults for Jupyter Server (port, proxy headers, credentials, culling).
# /usr/local/etc/jupyter overrides /etc/jupyter and is overridden by ~/.jupyter.
COPY railway_jupyter_server_config.py /usr/local/etc/jupyter/jupyter_server_config.py

# JupyterLab defaults: no news feed or update-check pop-ups on a server.
COPY overrides.json /opt/conda/share/jupyter/lab/settings/overrides.json

# Start hook, sourced by start.sh as root before Jupyter starts: seeds the
# /home/jovyan volume, fixes its ownership and prepares the login credentials.
COPY 20-railway-setup.sh /usr/local/bin/before-notebook.d/20-railway-setup.sh

# - Snapshot the image's home directory; it is copied into the empty volume on first boot.
# - Directory for the hashed password and token (readable by the users group only).
# - New conda environments go to ~/.conda/envs on the volume, so they survive redeploys.
RUN cp -a "/home/${NB_USER}" /opt/jovyan-home-seed && \
    install -d -m 0750 -o root -g "${NB_GID}" /etc/jupyter/railway && \
    chmod 0644 /usr/local/etc/jupyter/jupyter_server_config.py \
        /opt/conda/share/jupyter/lab/settings/overrides.json \
        /usr/local/bin/before-notebook.d/20-railway-setup.sh && \
    conda config --system --prepend envs_dirs "/home/${NB_USER}/.conda/envs" && \
    fix-permissions /opt/conda/share/jupyter/lab/settings

# tini is not PID 1 on Railway; registering it as a subreaper keeps zombie reaping.
# ~/.local/bin (pip --user scripts, on the volume) is appended, never prepended,
# so a user-installed package cannot shadow the image's jupyter binaries.
ENV TINI_SUBREAPER=true \
    PATH="${PATH}:/home/${NB_USER}/.local/bin"

# Start as root so start.sh can prepare the volume, then it drops to jovyan (uid 1000).
# ENTRYPOINT (tini -> start.sh) and CMD (start-notebook.py) come from the base image.
WORKDIR /home/${NB_USER}
