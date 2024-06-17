#!/bin/bash

#
# This script generates a "RDM Machine" using Multipass.
#
# Multipass is launching a Ubuntu 22.04 LTS machine (jammy) as that
# works with the current release of RDM (v11). Not sure the specs for
# the upcoming v12 release yet (expecting an announcement at 
# Open Repositories, June, 2024.
#
echo "Launch invenio-rdm"
if ! multipass launch jammy \
    --verbose \
    --name invenio-rdm \
    --memory 8G \
    --disk 150G \
    --cpus 2 \
    --cloud-init invenio-rdm.yaml; then
    echo
    echo "Failed to create invenio-rdm."
    echo
    exit 1
fi
if ! multipass info invenio-rdm; then
    echo
    echo 'failed to create invenio-rdm, aborting'
    echo
    exit 1
fi
if ! multipass exec invenio-rdm -- /usr/local/bin/install_rdm_nvm.bash; then
    echo
    echo 'WARNING: failed to to install nvm'
    echo 'Access your VM and run /usr/local/bin/install_rdm_nvm.bash'
    echo 'Access your VM and run /usr/local/bin/install_rdm_node.bash'
    echo
elif ! multipass exec invenio-rdm -- /usr/local/bin/install_rdm_node.bash; then
    echo
    echo 'WARNING: failed to to install, nvm, nodejs and npm'
    echo 'Access your VM and run /usr/local/bin/install_rdm_node.bash'
    echo
elif ! multipass restart invenio-rdm; then
    # Finally we need to restart the machine. 
    echo
    echo 'WARNING: restart failed, check logs on VM restart'
    echo
fi
RDM_IP_ADDRESS=$(multipass list | grep invenio-rdm | cut -c 43-58)
cat <<EOT

  Welcome to the RDM Machine. You can access if with

      multipass shell invenio-rdm

  There are some additional steps to take to get RDM working
  on your virtual machine.  If you want a vanilla instance
  run 

    setup_rdm_instance.bash v11.0

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
