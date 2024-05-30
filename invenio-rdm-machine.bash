#!/bin/bash

#
# This script generates a "RDM Machine" using Multipass.
#
# Multipass is launching a Ubuntu 20.04 LTS machine (focal) as that
# works with the current release of RDM (v11). Not sure the specs for
# the upcoming v12 release yet (expecting an announcement at 
# Open Repositories, June, 2024.
#
echo "Launch invenio-rdm"
if ! multipass launch focal \
	--name invenio-rdm \
	--memory 8G \
	--disk 150G \
	--cpus 2 \
	--cloud-init invenio-rdm-init.yaml; then
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
RDM_IP_ADDRESS=$(multipass list | grep invenio-rdm | cut -c 43-58)
cat <<EOT

  Weclome to the RDM Machine. You can access if with

      multipass shell invenio-rdm

  You can then run the follow script for configuring an
  RDM instance and development. These are available in
  /usr/local/bin.  Here is a brief list of the scripts
  provided with this virtual machine.

    menu_of_scripts.bash
    setup_rdm_instance.bash [RDM_VERSION]

  This last script will create a /Sites directory and launch
  the invenio-cli commands to create a new instance.

  The following are provided as a convenience. You should run them
  from your instance installaiton directory.

    invenio_ctl.bash
    dump_opensearch_indexes.bash
    restore_opensearch_indexes.bash
    invenio_sql_backup.bash
    invenio_sql_restore.bash
    invenio_sql_command.bash

  The first one sets up an RDM instance withe given and second ones are needed for
  RDM Projects. The rest are optional

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
