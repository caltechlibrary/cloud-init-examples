#!/bin/bash

INSTANCE_NAME="invenio-rdm"

#
# This script generates a "RDM Machine" using Multipass.
#
# Multipass is launching a Ubuntu 22.04 LTS machine (jammy) as that
# works with the current release of RDM (v11). Not sure the specs for
# the upcoming v12 release yet (expecting an announcement at 
# Open Repositories, June, 2024.
#
echo "Launch ${INSTANCE_NAME}"
if ! multipass launch jammy \
    --verbose \
    --name "${INSTANCE_NAME}" \
    --memory 8G \
    --disk 150G \
    --cpus 2 \
    --cloud-init invenio-rdm.yaml; then
    echo
    echo "Failed to create ${INSTANCE_NAME}."
    echo
    exit 1
fi
if ! multipass info "${INSTANCE_NAME}"; then
    echo
    echo 'failed to create ${INSTANCE_NAME}, aborting'
    echo
    exit 1
fi
echo "Installing RDM required software"
if ! multipass exec "${INSTANCE_NAME}" -- /usr/local/bin/install_rdm_nvm.bash; then
    echo
    echo 'WARNING: failed to to install nvm'
    echo 'Access your VM and run /usr/local/bin/install_rdm_nvm.bash'
    echo 'Access your VM and run /usr/local/bin/install_rdm_node.bash'
    echo
    exit 1
fi
if ! multipass exec "${INSTANCE_NAME}" -- /usr/local/bin/install_rdm_node.bash; then
    echo
    echo 'WARNING: failed to to install, nvm, nodejs and npm'
    echo 'Access your VM and run /usr/local/bin/install_rdm_node.bash'
    echo
    exit 1
fi
if ! multipass restart "${INSTANCE_NAME}"; then
    # Finally we need to restart the machine. 
    echo
    echo 'WARNING: restart failed, check logs on VM restart'
    echo
    exit 1
fi

# FIXME: This is where I would want to map the instance name to the 
# RDM instance and run setup_rdm_instance.bash remotely passing in the 
# Instance name and version id.

RDM_IP_ADDRESS=$(multipass list | grep "${INSTANCE_NAME}" | cut -c 43-58)
cat <<EOT

  Welcome to the RDM Machine. You can access if with

      multipass shell ${INSTANCE_NAME}

  There are some additional steps to take to get RDM working
  on your virtual machine.  If you want a vanilla instance
  run 

    setup_rdm_instance.bash INSTANCE_NAME v11.0

  If you want to run a copy of CaltechAUTHORS run

    setup_rdm_caltechauthors.bash

  Additional scripts are available for experimentation and
  development of your custom RDM instance.  To get the list of
  scripts run

    menu_of_scripts.bash

  You can grant yourself SSH access with the following
  command when you connect using multipass shell.

     ssh-keygen
         curl -L -o - https://github.com/${USER}.keys \\
         >>.ssh/authorized_keys

  This is handy so you can setup port forward for local
  services like.

  This is handy so you can setup port forward for local
  services like.

     ssh -L 8011:localhost:8011 ubuntu@${RDM_IP_ADDRESS}

EOT
