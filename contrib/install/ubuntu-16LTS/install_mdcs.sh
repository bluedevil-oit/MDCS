#!/usr/bin/env bash
# This script runs as the ${MDCS_USER}, so the environment has been setup since .bashrc and .bash_profile were updated to
#    load the environment file and set up the python virtual environment

if [[ $(whoami) != ${MDCS_USER} ]]; then # if the env did not get set up var value will be "" or if it's the wrong user it won't match
  echo "Please run this script ($0) as ${MDCS_USER}."
  exit
fi

# install/configure MDCS

cd ${MDCS_TARGET_DIR}

# update MDCS to mongo connection info
export tmpFile=$(mktemp)
echo 'Updating MDCS settings using temporary work file: ' $tmpFile
sed -e "s/mgi_user/${MDCS_MONGO_API_USER}/g" ${MDCS_TARGET_PATH}/mdcs/settings.py |
sed -e "s/mgi_password/${MDCS_MONGO_API_PWD}/g" > $tmpFile
cp ${tmpFile} ${MDCS_TARGET_PATH}/mdcs/settings.py

python manage.py migrate auth
python manage.py migrate
python manage.py collectstatic --noinput
python manage.py compilemessages

# https://stackoverflow.com/a/42812446
./manage.py shell -c "from django.contrib.auth.models import User; User.objects.create_superuser(\"${MDCS_ADMIN_USER_NAME}\", \"${MDCS_ADMIN_EMAIL}\", \"${MDCS_ADMIN_USER_PWD}\")"
