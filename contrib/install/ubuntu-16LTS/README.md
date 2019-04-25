# MDCS Ubuntu 16 LTS installer
#### This installer is provided without warranty. The user assumes all risk for executing this installer.
####   It is advisable that before using the installer you review the installer code in the repository.

##### NOTE: Installation process may change over time. Monitor this README for updates.

# Installation
#### This installer supports Ubuntu 16LTS ONLY and may not work (probably won't) on other versions or distributions of Linux.

#### The target system should have least 2GB of internal memory and at least 15G (base install - more if large datasets stored) of disk space available.

##### NOTE: This installer is tuned to a VM installation environment for development purposes only.
#####   If you're creating a production or other shared environment, then adjust the installation script accordingly.
#####   The installer will create a user called 'mdcs' and install mdcs so that the mdcs user has ownership and full access.
#####   The script file MDCS_HOME/mdcs_vars will be created to contain passwords and other configuration information for services like Mongo. 
#####   The MDCS_HOME/mdcs_vars file will be set so that no users other than 'mdcs' and 'root' are able to read the file. 
##### The file will be 'sourced' by the  mdcs user's login scripts to ensure availability of the variables. 
##### These variables are not accessible out side of the mdcs user environment (except for root of course). The file may also be sourced by service scripts running under the mdcs or root users.
##### Also, the user will be given sudo privileges (easily commented out if necessary e.g. a production server). This makes it easier to manage some services and the environment if logged in as the mdcs user. This is probably not appropriate in a production or shared environment!

#### It's probably best to start with a clean VM i.e. newly installed Ubuntu instance.


- MDCS will be installed into the mdcs_app directory under the 'mdcs' user directory - configured to be /mdcs. The full path is /mdcs/mdcs_app.
- Run the following commands in a terminal on the target system to prime and start the installation (the executing user needs sudo access).
-   NOTE: Usually, when Ubuntu 16 LTS is installed, the user specified during install is given sudo access by default.
```
export MDCS_ADMIN_EMAIL='mdcs_admin@example.com' # replace this with the actual admin user email address to use
export MDCS_INSTALL_FORK='MYFORK' # use 'usnistgov' GitHub fork name if you do not intend to make changes and generate pull requests
export MDCS_INSTALL_BRANCH='develop' # Use a tag like '2.1.0' for production or use a different branch for development
# NOTE: the following override tag MAY BE optional IF you know that you have access to ALL the MDCS components via the MDCS_INSTALL_BRANCH
#   IF NOT, then the resulting install will fail.  This override allows the MDCS components to be pulled
#   from tag rather than the specified fork. Note also that if the MDCS_INSTALL_BRANCH is set to a release tag the override is NOT necessary.  
export MDCS_INSTALL_OVERRIDE_TAG="" # not necessary if MDCS_INSTALL_BRANCH is set to a release tag like '2.1.0' or it is know that the branch used has access to mdcs components
export MDCS_USER=mdcs # mdcs username 
export MDCS_HOME_PARENT_DIR='/' # home directory for the user will be created in this directory e.g. /mdcs (/home/USERNAME is usually the default)
export MDCS_MONGO_PORT="27017" # override if necessary
export MDCS_INSTALL_DIST="ubuntu-16LTS"
sudo apt-get update
sudo apt-get install -y curl
curl -Lks https://raw.githubusercontent.com/${MDCS_INSTALL_FORK}/mdcs/${MDCS_INSTALL_BRANCH}/contrib/install/${MDCS_INSTALL_DIST}/install.sh > ./mdcsinstall.sh
chmod a+x ./mdcsinstall.sh
sudo -E ./mdcsinstall.sh 2>&1 | tee mdcsinstall.log # -E copies environment
```
##### The installation will require several minutes. For troubleshooting, a log (mdcsinstall.log) will is created by the installer.
#### The installer enables an Apache based WSGI environment and the MDCS server will be available at the default http port(80) at address http://localhost


##### Configuration
- Login to the MDCS server as the configured super user and configure MDCS using the MDCS configuration documentation.
- To obtain the super user id and password:
-    sudo su - mdcs
-    echo $MDCS_ADMIN_USER_NAME
-    echo $MDCS_ADMIN_USER_PWD

