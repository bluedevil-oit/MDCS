#!/usr/bin/env bash
# NOTE: this script is used by the celery systemd service to run celery in the MDCS virtual environment
source ${MDCS_HOME}/${MDCS_VENV}/bin/activate
/bin/sh ${MDCS_CELERY_BIN} $*
