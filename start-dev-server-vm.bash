#!/bin/bash
MACHINE="dev-server"
##
## multipass set client.primary-name="${MACHINE}"
## multipass launch --name "${MACHINE}" \
##     --cpus 2 --mem 2G --disk 20G \
##     --cloud-init ${MACHINE}-init.yaml
## multipass restart "${MACHINE}"
## multipass mount src $MACHINE:src
##

#
# Check if we're providing a machine name or using the existing primary name
#
#PRIMARY_NAME=$(multipass get client.primary-name)
#if [ "${PRIMARY_NAME}" != "$MACHINE" ]; then
#	echo "Changin primary name from $PRIMARY_NAME to $MACHINE"
#	multipass set client.primary-name=$MACHINE
#fi

#
# Figure out if we're launching, starting or machine is already active
#
if multipass list | grep $MACHINE >/dev/null; then
	VM_STATE=$(multipass info $MACHINE | grep -i State)
	case "${VM_STATE}" in
	*Stopped)
		multipass start $MACHINE
		;;
	*Running)
		echo "$MACHINE is already running"
		;;
	*)
		echo "VM is $VM_STATE, wait and run again"
		exit 1
		;;
	esac
else
	echo "Launching $MACHINE"
	multipass launch --name $MACHINE \
		--cpus 2 --mem 2G --disk 20G \
		--cloud-init $MACHINE-init.yaml
	multipass restart "${MACHINE}"
fi

#
# If a src directory exists mount it
#
if [ -d src ]; then
	multipass mount src $MACHINE:src
fi

#
# If a Sites directory exists mount it
#
if [ -d Sites ]; then
	multipass mount Sites $MACHINE:Sites
fi

#
# Make sure tcsh is installed and is set to the user shell
#
if [ -f staff-favorites.bash ]; then
  multipass transfer staff-favorites.bash $MACHINE:.
fi

#
# Display state of machine
#
multipass info $MACHINE
