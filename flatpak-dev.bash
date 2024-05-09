#!/bin/bash

#
# This script generates a "Flatpak Dev" using Multipass.
#
echo "Launch flatpak-dev"
multipass launch \
	--name flatpak-dev \
	--memory 4G \
	--disk 150G \
	--cpus 2 \
	--cloud-init flatpak-init.yaml
multipass info flatpak-dev
NEWT_IP_ADDRESS=$(multipass list | grep flatpak-dev | cut -c 43-58)
cat <<EOT

  Weclome to the Flatpak Dev. You can
  access if with 

      multipass shell flatpak-dev

  You can then run one or more additional
  configuration scripts to add additional
  software for development.

    01-setup-scripts.bash
    02-add-python-packages.bash
    03-add-go-and-caltechlibrary-tools.bash
    04-ghcup-install.bash
    05-pandoc-build.bash
    06-postgrest-build.bash
    07-add-opensearch.bash
    08-add-solr.bash

  The first and second ones are needed for
  Newt Projects. The rest are optional

  You can grant yourself SSH access with the following
  command when you connect using multipass shell.

     ssh-keygen
	 curl -L -o - https://github.com/${USER}.keys \
	              >>.ssh/authorized_keys

  This is handy so you can setup port forward for local
  services like.

     ssh -L 8011:localhost:8011 ubuntu@${NEW_IP_ADDRESS}
EOT
