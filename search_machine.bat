@echo off
REM #!/bin/bash
REM 
REM #
REM # This script generates a "Search Machine" using Multipass. Initial 
REM # focus is on PageFind and Solr. 
REM #
REM # I am using this machine to explore search and citeproc (JS implementation).
REM #
REM # Multipass is launching a Ubuntu 24.04 LTS machine.
REM #
echo "Launch search-machine"
multipass launch jammy^
	-vvvv^
	--cpus 2^
	--memory 4G^
	--name search-machine^
	--cloud-init search-init.yaml
multipass restart search-machine


VM_IP_ADDRESS=$(multipass list | grep search-machine | cut -c 43-58)
echo
echo 
echo  Welcome to the Search Machine. You can access if with
echo
echo      multipass shell search-machine
echo
echo  Additional scripts are available for setup and experimentation.
echo  The scripts are installed into /usr/local/bin.
echo  To get the list of scripts run
echo
echo    menu_of_scripts.bash
echo
echo  You can grant yourself SSH access with the following
echo  command when you connect using multipass shell.
echo
echo     ssh-keygen
echo         curl -L -o - https://github.com/${USER}.keys \\
echo         >>.ssh/authorized_keys
echo
echo  This is handy so you can setup port forward for local
echo  services like.
echo
echo  This is handy so you can setup port forward for local
echo  services like.
echo
echo     ssh -L 8011:localhost:8011 ubuntu@${VM_IP_ADDRESS}
echo
