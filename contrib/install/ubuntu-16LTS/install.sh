#!/usr/bin/env bash

## NOTE: get the tagged release i.e. tags/2.0.1 for production installs vs. just a branch like develop
##     git clone -b "2.0.1" https://github.com/${MDCS_INSTALL_FORK}/MDCS.git
##      note that the -b branch can be a branch name or tag name - use a tag name to pick up the latest release e.g. 2.0.1
##      Note also, that a tarball of a tagged release can be downloaded using:
##             curl -Ls https://github.com/usnistgov/MDCS/tarball/2.0.1 > mdcs-2.0.1.tgz
##      Single file: https://raw.githubusercontent.com/usnistgov/MDCS/2.0.1/contrib/install/ubuntu-16LTS/install.sh

# export MONGO_DUMP_DOWNLOAD_LOCATION=""
# export MDCS_INSTALL_FORK=""
# export MDCS_INSTALL_BRANCH=""
# export MDCS_ADMIN_EMAIL=""

# export mdcspw=""

export MDCS_INSTALL_DIST="ubuntu-16LTS"

# not handling upgrades yet, so the following lines are disabled
#if [[ -z ${MONGO_DUMP_DOWNLOAD_LOCATION} ]] ; then
#  echo 'Export MONGO_DUMP_DOWNLOAD_LOCATION before running installer'
#  exit
#fi


if [[ -z ${MDCS_INSTALL_FORK} ]]; then
  echo 'Export MDCS_INSTALL_FORK before running installer'
  echo "hint: possibly your github user id or 'usnistgov'"
  exit
fi
if [[ -z ${MDCS_INSTALL_BRANCH} ]]; then
  echo 'Export MDCS_INSTALL_BRANCH before running installer'
  echo "hint: usually, this should be: 'develop'"
  exit
fi
if [[ -z ${MDCS_USER} ]]; then
  echo 'Export MDCS_USER before running installer'
  echo "hint: possibly 'mdcs' or even something like 'frodo'"
  exit
fi
if [[ -z ${MDCS_HOME_PARENT_DIR} ]]; then
  echo 'Export MDCS_HOME_PARENT_DIR before running installer'
  echo "hint: possibly '/' or  '/home'. The parent directory should already exist."
  exit
fi

if [[ -z ${MDCS_MONGO_PORT} ]]; then
  export MDCS_MONGO_PORT="27017"
fi


if [[ $(whoami) != "root" ]]; then
  echo 'Please run this script as root (sudo).'
  exit
fi

if [[ -z $(which pip) ]]; then
  echo 'Installing pip - python package installer'
  curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
  (su root -c 'python get-pip.py')
fi

echo installing git
apt-get install -y git
sudo apt-get install -y vim

echo add user ${MDCS_USER}
export MDCS_HOME=${MDCS_PARENT_DIR}/${MDCS_USER}
export MDCS_VARS="${MDCS_HOME}/mdcs_vars"
useradd --home-dir ${MDCS_HOME} --shell /bin/bash -G sudo -M -U ${MDCS_USER}
if [[ ! -d ${MDCS_HOME} ]]; then
  (su root -c "mkdir ${MDCS_HOME}; chown -R ${MDCS_USER}:${MDCS_USER} ${MDCS_HOME}")
fi
ls -lasR ${MDCS_HOME}

touch ${MDCS_VARS}
chown  ${MDCS_USER}:${MDCS_USER} ${MDCS_VARS}
chmod og-rwx ${MDCS_VARS} ## only the mdcs user and root can read or write variables file
export MDCS_VENV="mdcs_env"

export MDCS_TARGET_DIR="mdcs_app"
export MDCS_TARGET_PATH="${MDCS_HOME}/${MDCS_TARGET_DIR}"
export MDCS_INSTALLER_PATH=${MDCS_HOME}/mdcs_installer

if [[ ! -z ${mdcspw} ]]; then # it is possible to set the mdcs password via this script, but it's not in the README
  echo 'setting mdcs user password from variable ${mdcspw}'
  echo ${MDCS_USER}:${mdcspw} | sudo chpasswd # NOTE: system owner can add mdcs password manually later after install
fi


(su ${MDCS_USER} -c "mkdir -p ${MDCS_TARGET_PATH}")
(su ${MDCS_USER} -c "mkdir -p ${MDCS_INSTALLER_PATH}")

pip install virtualenv
(su - ${MDCS_USER} -c "virtualenv ${MDCS_VENV}")
echo "source ${MDCS_HOME}/${MDCS_VENV}/bin/activate" >> ${MDCS_HOME}/.bashrc
echo "source ${MDCS_VARS}" >> ${MDCS_HOME}/.bashrc
echo "source ${MDCS_HOME}/${MDCS_VENV}/bin/activate" >> ${MDCS_HOME}/.bash_profile
echo "source ${MDCS_VARS}" >> ${MDCS_HOME}/.bash_profile

chown ${MDCS_USER}:${MDCS_USER} ${MDCS_HOME}/.bashrc
chown ${MDCS_USER}:${MDCS_USER} ${MDCS_HOME}/.bash_profile

(su - ${MDCS_USER} -c "pip install --upgrade pip")
(su - ${MDCS_USER} -c "pip install shortuuid")

echo -e '#!/usr/bin/env python\nimport shortuuid\nprint(shortuuid.ShortUUID().random(length=22))\n' > ${MDCS_INSTALLER_PATH}/getuuid.py
chmod a+x ${MDCS_INSTALLER_PATH}/getuuid.py

export MDCS_MONGO_DB_PATH=${MDCS_HOME}/data/db
export MDCS_MONGO_ADMIN_USER=admin_$(su - ${MDCS_USER} -c "${MDCS_INSTALLER_PATH}/getuuid.py") # friends don't let friends set default userids and passwords
export MDCS_MONGO_ADMIN_PWD=$(su - ${MDCS_USER} -c "${MDCS_INSTALLER_PATH}/getuuid.py")
export MDCS_MONGO_OWNER_USER=owner_$(su - ${MDCS_USER} -c "${MDCS_INSTALLER_PATH}/getuuid.py")
export MDCS_MONGO_OWNER_PWD=$(su - ${MDCS_USER} -c "${MDCS_INSTALLER_PATH}/getuuid.py")
export MDCS_MONGO_API_USER=user_$(su - ${MDCS_USER} -c "${MDCS_INSTALLER_PATH}/getuuid.py")
export MDCS_MONGO_API_PWD=$(su - ${MDCS_USER} -c "${MDCS_INSTALLER_PATH}/getuuid.py")
export MDCS_ADMIN_USER_NAME=super_$(su - ${MDCS_USER} -c "${MDCS_INSTALLER_PATH}/getuuid.py")
export MDCS_ADMIN_USER_PWD=$(su - ${MDCS_USER} -c "${MDCS_INSTALLER_PATH}/getuuid.py")
export MDCS_CELERY_APP=${MDCS_USER}
export MDCS_CELERY_NODES="worker"
export MDCS_CELERY_OPTS=""
export MDCS_CELERY_BIN="${MDCS_HOME}/${MDCS_VENV}/bin/celery"
export MDCS_CELERY_SCRIPT="${MDCS_HOME}/runcelery.sh"
export MDCS_CELERY_PID_FILE="${MDCS_HOME}/${MDCS_VENV}/var/run/celery/%n.pid"
export MDCS_CELERY_LOG_FILE="${MDCS_HOME}/${MDCS_VENV}/var/log/celery/%n%I.log"
export MDCS_CELERY_LOG_LEVEL="INFO"
export MDCS_CELERYBEAT_PID_FILE="${MDCS_HOME}/${MDCS_VENV}/var/run/celery/beat.pid"
export MDCS_CELERYBEAT_LOG_FILE="${MDCS_HOME}/${MDCS_VENV}/var/log/celery/beat.log"
#export MDCS_CELERY_WORKDIR="${MDCS_HOME}/${MDCS_VENV}/opt/celery"
export MDCS_CELERY_WORKDIR="${MDCS_HOME}"
(su - ${MDCS_USER} -c "mkdir -p ${MDCS_HOME}/${MDCS_VENV}/var/run")
(su - ${MDCS_USER} -c "mkdir -p ${MDCS_HOME}/${MDCS_VENV}/var/log")
(su - ${MDCS_USER} -c "mkdir -p ${MDCS_HOME}/${MDCS_VENV}/opt/celery")

# write the variables created to the mdcs_vars file so the mdcs user knows them at login
echo export MDCS_INSTALL_DIST=${MDCS_INSTALL_DIST} >> ${MDCS_VARS}
echo export MDCS_USER=${MDCS_USER} >> ${MDCS_VARS}
echo export MDCS_HOME=${MDCS_HOME} >> ${MDCS_VARS}
echo export MDCS_INSTALL_FORK=${MDCS_INSTALL_FORK} >> ${MDCS_VARS}
echo export MDCS_INSTALL_BRANCH=${MDCS_INSTALL_BRANCH} >> ${MDCS_VARS}
echo export MDCS_TARGET_DIR=${MDCS_TARGET_DIR} >> ${MDCS_VARS}
echo export MDCS_TARGET_PATH=${MDCS_TARGET_PATH} >> ${MDCS_VARS}
echo export MDCS_INSTALL_PATH=${MDCS_TARGET_PATH} >> ${MDCS_VARS}
echo export MDCS_VENV=${MDCS_VENV} >> ${MDCS_VARS}
echo export MDCS_MONGO_DB_PATH=${MDCS_MONGO_DB_PATH} >> ${MDCS_VARS}
echo export MDCS_MONGO_PORT=${MDCS_MONGO_PORT} >> ${MDCS_VARS}
echo export MDCS_MONGO_ADMIN_USER=${MDCS_MONGO_ADMIN_USER} >> ${MDCS_VARS}
echo export MDCS_MONGO_ADMIN_PWD=${MDCS_MONGO_ADMIN_PWD} >> ${MDCS_VARS}
echo export MDCS_MONGO_OWNER_USER=${MDCS_MONGO_OWNER_USER} >> ${MDCS_VARS}
echo export MDCS_MONGO_OWNER_PWD=${MDCS_MONGO_OWNER_PWD} >> ${MDCS_VARS}
echo export MDCS_MONGO_API_USER=${MDCS_MONGO_API_USER} >> ${MDCS_VARS}
echo export MDCS_MONGO_API_PWD=${MDCS_MONGO_API_PWD} >> ${MDCS_VARS}
echo export MDCS_ADMIN_USER_NAME=${MDCS_ADMIN_USER_NAME} >> ${MDCS_VARS}
echo export MDCS_ADMIN_USER_PWD=${MDCS_ADMIN_USER_PWD} >> ${MDCS_VARS}
echo export MDCS_CELERY_APP=${MDCS_CELERY_APP} >> ${MDCS_VARS}
echo export MDCS_CELERY_NODES=${MDCS_CELERY_NODES} >> ${MDCS_VARS}
echo export MDCS_CELERY_OPTS=${MDCS_CELERY_OPTS} >> ${MDCS_VARS}
echo export MDCS_CELERY_BIN=${MDCS_CELERY_BIN} >> ${MDCS_VARS}
echo export MDCS_CELERY_SCRIPT=${MDCS_CELERY_SCRIPT} >> ${MDCS_VARS}
echo export MDCS_CELERY_PID_FILE=${MDCS_CELERY_PID_FILE} >> ${MDCS_VARS}
echo export MDCS_CELERY_LOG_FILE=${MDCS_CELERY_LOG_FILE} >> ${MDCS_VARS}
echo export MDCS_CELERY_LOG_LEVEL=${MDCS_CELERY_LOG_LEVEL} >> ${MDCS_VARS}
echo export MDCS_CELERYBEAT_PID_FILE=${MDCS_CELERYBEAT_PID_FILE} >> ${MDCS_VARS}
echo export MDCS_CELERYBEAT_LOG_FILE=${MDCS_CELERYBEAT_LOG_FILE} >> ${MDCS_VARS}
echo export MDCS_CELERY_WORKDIR=${MDCS_CELERY_WORKDIR} >> ${MDCS_VARS}

# install mongo
echo 'installing mongo (NOTE: installing 3.6)'
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.6 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.6.list
apt-get update
apt-get install -y mongodb-org
mkdir -p ${MDCS_MONGO_DB_PATH}
chown mongodb:mongodb ${MDCS_MONGO_DB_PATH}
curl -Lks https://raw.githubusercontent.com/${MDCS_INSTALL_FORK}/MDCS/${MDCS_INSTALL_BRANCH}/contrib/install/mongo/mongoConfig > /etc/mongod.conf

cat /etc/mongod.conf

export tmpFile=$(mktemp)

echo 'Updating mongo config using temporary work file: ' $tmpFile
# note: sed can use , instead of / for delimiting substitutions which works well when data contains slashes e.g. directory paths
sed -e 's,${MDCS_MONGO_PORT},'${MDCS_MONGO_PORT}',g' /etc/mongod.conf |
sed -e 's,${MDCS_MONGO_DB_PATH},'${MDCS_MONGO_DB_PATH}',g'   |
sed -r '/^\s*$/d' > $tmpFile  # GNU sed extension to remove blank lines
cp ${tmpFile} /etc/mongod.conf

systemctl enable mongod
systemctl start mongod

(su ${MDCS_USER} -c "curl -Lks https://raw.githubusercontent.com/${MDCS_INSTALL_FORK}/MDCS/${MDCS_INSTALL_BRANCH}/contrib/install/mongo/mongoSetupAdminUser.sh > ${MDCS_INSTALLER_PATH}/mongoSetupAdminUser.sh")
chmod a+x ${MDCS_INSTALLER_PATH}/mongoSetupAdminUser.sh

(su ${MDCS_USER} -c "curl -Lks https://raw.githubusercontent.com/${MDCS_INSTALL_FORK}/MDCS/${MDCS_INSTALL_BRANCH}/contrib/install/mongo/mongoSetupApiUser.sh > ${MDCS_INSTALLER_PATH}/mongoSetupApiUser.sh")
chmod a+x ${MDCS_INSTALLER_PATH}/mongoSetupApiUser.sh

echo -e "\n" | nc localhost ${MDCS_MONGO_PORT}
while [[ $? -ne 0 ]]; do
  echo waiting for mongod listener to wake up
  sleep 2
  echo -e "\n" | nc localhost ${MDCS_MONGO_PORT}
done

(su - ${MDCS_USER} -c "${MDCS_INSTALLER_PATH}/mongoSetupAdminUser.sh")
(su - ${MDCS_USER} -c "${MDCS_INSTALLER_PATH}/mongoSetupApiUser.sh")

apt-get install -y gettext
apt-get install -y build-essential

# install redis
wget http://download.redis.io/redis-stable.tar.gz
tar xzf redis-stable.tar.gz
pushd redis-stable
make install
popd

# create redis user and group
useradd --shell /bin/true -M -U redis # no home directory and no shell
curl -Lks https://raw.githubusercontent.com/${MDCS_INSTALL_FORK}/MDCS/${MDCS_INSTALL_BRANCH}/contrib/install/${MDCS_INSTALL_DIST}/redis.service > /etc/systemd/system/redis.service

mkdir /etc/redis
chown -R redis:redis /etc/redis

mkdir -p /var/lib/redis
chown -R redis:redis /var/lib/redis

mkdir -p /var/run/redis
chown -R redis:redis /var/run/redis

curl -Lks https://raw.githubusercontent.com/${MDCS_INSTALL_FORK}/MDCS/${MDCS_INSTALL_BRANCH}/contrib/install/${MDCS_INSTALL_DIST}/redis.conf > /etc/redis/redis.conf

systemctl enable redis
systemctl restart redis


(su - ${MDCS_USER} -c "git clone -b ${MDCS_INSTALL_BRANCH} https://github.com/${MDCS_INSTALL_FORK}/MDCS.git ${MDCS_TARGET_DIR}")

## NOTE: TEMPORARY OVERRIDE! Since only 2.0.1 components are published, we force the requirements lists to 2.0.1 level
(su - ${MDCS_USER} -c "curl -Lks https://raw.githubusercontent.com/${MDCS_INSTALL_FORK}/MDCS/2.0.1/requirements.txt > ${MDCS_TARGET_DIR}/requirements.txt")
(su - ${MDCS_USER} -c "curl -Lks https://raw.githubusercontent.com/${MDCS_INSTALL_FORK}/MDCS/2.0.1/requirements.core.txt > ${MDCS_TARGET_DIR}/requirements.core.txt")
## END OVERRIDE

(su - ${MDCS_USER} -c "cd ${MDCS_TARGET_DIR}; pip install -e git://github.com/MongoEngine/django-mongoengine.git@v0.2.1#egg=django-mongoengine; pip install --no-cache-dir -r requirements.txt; pip install --no-cache-dir -r requirements.core.txt")
(su - ${MDCS_USER} -c "cp ${MDCS_TARGET_DIR}/contrib/install/${MDCS_INSTALL_DIST}/runcelery.sh ${MDCS_HOME}")
# cannot install celery service until celery is installed via requirements.txt
# ensure that celery service is running before installing/starting mdcs
# letting celery run as mdcs user for access to environment
cp ${MDCS_TARGET_PATH}/contrib/install/${MDCS_INSTALL_DIST}/celery.service /etc/systemd/system
export tmpFile=$(mktemp)
echo 'Updating /etc/systemd/system/celery.service using temporary work file: ' $tmpFile
sed -e 's,${MDCS_VARS},'${MDCS_VARS}',g' /etc/systemd/system/celery.service |
sed -e 's,${MDCS_USER},'${MDCS_USER}',g'   |
sed -e 's,${MDCS_CELERY_BIN},'${MDCS_CELERY_BIN}',g'   |
sed -e 's,${MDCS_CELERY_SCRIPT},'${MDCS_CELERY_SCRIPT}',g'   |
sed -e 's,${MDCS_CELERY_NODES},'${MDCS_CELERY_NODES}',g'   |
sed -e 's,${MDCS_CELERY_APP},'${MDCS_CELERY_APP}',g'   |
sed -e 's,${MDCS_CELERY_WORKDIR},'${MDCS_CELERY_WORKDIR}',g'   |
sed -e 's,${MDCS_CELERY_PID_FILE},'${MDCS_CELERY_PID_FILE}',g'   |
sed -e 's,${MDCS_CELERY_LOG_FILE},'${MDCS_CELERY_LOG_FILE}',g'   |
sed -e 's,${MDCS_CELERY_LOG_LEVEL},'${MDCS_CELERY_LOG_LEVEL}',g'   |
sed -e 's,${MDCS_CELERY_OPTS},'${MDCS_CELERY_OPTS}',g'  > $tmpFile
cp ${tmpFile} /etc/systemd/system/celery.service

cp ${MDCS_TARGET_PATH}/contrib/install/${MDCS_INSTALL_DIST}/celerybeat.service /etc/systemd/system
export tmpFile=$(mktemp)
echo 'Updating /etc/systemd/system/celerybeat.service using temporary work file: ' $tmpFile
sed -e 's,${MDCS_VARS},'${MDCS_VARS}',g' /etc/systemd/system/celerybeat.service |
sed -e 's,${MDCS_USER},'${MDCS_USER}',g'   |
sed -e 's,${MDCS_CELERY_BIN},'${MDCS_CELERY_BIN}',g'   |
sed -e 's,${MDCS_CELERY_SCRIPT},'${MDCS_CELERY_SCRIPT}',g'   |
sed -e 's,${MDCS_CELERY_APP},'${MDCS_CELERY_APP}',g'   |
sed -e 's,${MDCS_CELERYBEAT_PID_FILE},'${MDCS_CELERYBEAT_PID_FILE}',g'   |
sed -e 's,${MDCS_CELERYBEAT_LOG_FILE},'${MDCS_CELERYBEAT_LOG_FILE}',g'   |
sed -e 's,${MDCS_CELERY_LOG_LEVEL},'${MDCS_CELERY_LOG_LEVEL}',g' > $tmpFile
cp ${tmpFile} /etc/systemd/system/celerybeat.service

systemctl enable celery
systemctl restart celery
systemctl enable celerybeat
systemctl restart celerybeat

(su ${MDCS_USER} -c "curl -Lks https://raw.githubusercontent.com/${MDCS_INSTALL_FORK}/MDCS/${MDCS_INSTALL_BRANCH}/contrib/install/${MDCS_INSTALL_DIST}/install_mdcs.sh > ${MDCS_INSTALLER_PATH}/install_mdcs.sh")

# install and configure mdcs
chmod a+x ${MDCS_INSTALLER_PATH}/install_mdcs.sh
(su - ${MDCS_USER} -c "${MDCS_INSTALLER_PATH}/install_mdcs.sh")
(su - ${MDCS_USER} -c "ln -s ${MDCS_TARGET_PATH}/contrib/install/mongo/mongocli ${MDCS_HOME}/mongocli")

# TODO install apache, wsgi and configure wsgi for mdcs

echo "if you would like to login as ${MDCS_USER} from the ubuntu login page, execute \"sudo passwd ${MDCS_USER}\" and set a password to use from the login page"
echo "Otherwise you should be able to get into the ${MDCS_USER} environment from the console using \"sudo su - ${MDCS_USER}\""
