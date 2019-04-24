#!/usr/bin/env bash
# NOTE: this script is used by the celery systemd service to run celery in the MDCS virtual environment
source ./mdcs_vars # HACK!
source ${MDCS_HOME}/${MDCS_VENV}/bin/activate
/usr/bin/env bash -c "${MDCS_CELERY_BIN} $*"

