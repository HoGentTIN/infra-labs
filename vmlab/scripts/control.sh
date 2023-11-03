#! /bin/bash
#
# Provisioning script for Ansible control node

#--------- Bash settings ------------------------------------------------------

# Enable "Bash strict mode"
set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't mask errors in piped commands

#--------- Variables ----------------------------------------------------------

# Location of provisioning scripts and files
export readonly PROVISIONING_SCRIPTS="/vagrant/scripts/"
# Location of files to be copied to this server
export readonly PROVISIONING_FILES="${PROVISIONING_SCRIPTS}/${HOSTNAME}"

#---------- Load utility functions --------------------------------------------

source ${PROVISIONING_SCRIPTS}/util.sh

#---------- Provision host ----------------------------------------------------

log "Starting server specific provisioning tasks on host ${HOSTNAME}"

log "Installing Ansible and dependencies"

dnf install --assumeyes \
  epel-release

dnf install --assumeyes \
  bash-completion \
  bats \
  bind-utils \
  mc \
  psmisc \
  python3-libselinux \
  python3-libsemanage \
  python3-netaddr \
  python3-pip \
  python3-PyMySQL \
  sshpass \
  tree \
  vim-enhanced

sudo --login --non-interactive --user=vagrant -- \
  pip install ansible
