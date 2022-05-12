#!/bin/bash
MACHINE=minimal-dev

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
    esac
else 
    CLOUD_INIT="$MACHINE-local.yaml"
    if [ ! -f "$CLOUD_INIT" ]; then
        CLOUD_INIT="$MACHINE-init.yaml"
    fi
    echo "Launching $MACHINE";
    multipass launch --name $MACHINE \
        --cpus 4 --mem 8G --disk 50G \
        --cloud-init $CLOUD_INIT
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
