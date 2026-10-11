#!/bin/bash
# Railway start hook for JupyterLab.
#
# Sourced by the Docker Stacks start.sh (bash) from before-notebook.d, as root,
# after the NB_USER/NB_UID handling and right before Jupyter is started as
# NB_USER. Being sourced means `unset` below removes the variables from the
# environment Jupyter, its kernels and terminals inherit.

_rw_home="/home/${NB_USER}"
_rw_seed="/opt/jovyan-home-seed"
_rw_secrets="/etc/jupyter/railway"

if [ "$(id -u)" = "0" ]; then
    # Railway volumes are ext4 and carry an empty lost+found directory.
    rmdir "${_rw_home}/lost+found" 2>/dev/null || true

    # First boot on an empty volume: copy the image's home files (.bashrc with
    # the conda hook, .profile, ~/work, matplotlib font cache, config stubs).
    if [ ! -e "${_rw_home}/.railway-home-seeded" ]; then
        _log_info "Seeding ${_rw_home} from ${_rw_seed}"
        cp -a --update=none "${_rw_seed}/." "${_rw_home}/" || _log_warn "Could not copy all seed files"
        touch "${_rw_home}/.railway-home-seeded"
        chown "${NB_UID}:${NB_GID}" "${_rw_home}/.railway-home-seeded"
    fi

    # The volume root is created root-owned; hand it to the notebook user.
    # Non-recursive on purpose: a large volume would make every start slow.
    chown "${NB_UID}:${NB_GID}" "${_rw_home}"
    chmod 2770 "${_rw_home}"

    # Credentials: hash the password here so the plain value never reaches
    # the Jupyter process, notebooks or terminals.
    install -d -m 0750 -o root -g "${NB_GID}" "${_rw_secrets}"
    rm -f "${_rw_secrets}/hashed_password" "${_rw_secrets}/token"
    if [ -n "${JUPYTER_PASSWORD:-}" ]; then
        if (umask 027 && python -c 'import os; from jupyter_server.auth import passwd; print(passwd(os.environ["JUPYTER_PASSWORD"]))' \
            >"${_rw_secrets}/hashed_password"); then
            chgrp "${NB_GID}" "${_rw_secrets}/hashed_password"
        else
            rm -f "${_rw_secrets}/hashed_password"
            _log_warn "Hashing JUPYTER_PASSWORD failed; password login is disabled, token login still works"
        fi
    else
        _log_warn "JUPYTER_PASSWORD is empty; log in with the token instead"
    fi
    if [ -n "${JUPYTER_TOKEN:-}" ]; then
        (umask 027 && printf '%s' "${JUPYTER_TOKEN}" >"${_rw_secrets}/token")
        chgrp "${NB_GID}" "${_rw_secrets}/token"
    fi
    unset JUPYTER_PASSWORD JUPYTER_TOKEN
fi

unset _rw_home _rw_seed _rw_secrets
