#!/bin/bash

#
# This script generates a "Search Machine" using Multipass. Initial 
# focus is on PageFind and Solr. 
#
# I am using this machine to explore search and citeproc (JS implementation).
#
# Multipass is launching a Ubuntu 24.04 LTS machine.
#
echo "Launch search-machine"
multipass launch jammy \
	-vv \
	--cpus 2 \
	--memory 4G \
	--name search-machine \
	--cloud-init search-machine.yaml
echo "Restarting VM"
if ! multipass restart search-machine; then
	echo
	echo 'failed multipass restart, aborting'
	echo
	exit 1
fi
VM_IP_ADDRESS=$(multipass list | grep search-machine | cut -c 43-58)
cat <<EOT

  Welcome to the Search Machine. You can access if with

      multipass shell search-machine

  Additional scripts are available for setup and experimentation.
  The scripts are installed into /usr/local/bin.
  To get the list of scripts run

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

     ssh -L 8011:localhost:8011 ubuntu@${VM_IP_ADDRESS}

EOT
