#!/bin/bash

function usage () {
    APP_NAME=$(basename "$0")
    cat <<EOT

NAME

   $APP_NAME

USAGE

   $APP_NAME MACHINE_NAME [MACHINE_SIZE] [UBUNTU_VERSION]

SYNOPSIS

$APP_NAME will start a Multipass virtual machine or
create it if it does not exist. It looks for a cloud init
YAML file using the machine name followed by "-init.yaml".

MACHINE SIZES

The machine sizes are based on AWS T4g series of machine
sizes.  Sizes include nano, micro, small, medium, large,
xlarge and 2xlarge.  The CPU count and memory settings
see https://aws.amazon.com/ec2/instance-types/ or read
the source file for $APP_NAME.

IMAGE

A specific image we'll be using. The current use case is to 
indicate a specific version of ubuntu.

EXAMPLE

In this example we'll start an machine name "invenio" and
if it does not exist it will be created with a size of xlarge
utilizing ubuntu 20.04 (focal).

    $APP_NAME invenio xlarge focal

EOT
}

#
# Check if we're providing a machine name or using the existing primary name
#
if [ "$1" = "" ]; then
    # MACHINE=$(multipass get client.primary-name)
    usage
    exit 0
else
    case "$1" in
        -h*)
        usage
        exit 0
        ;;
        help)
        usage
        exit 0
        ;;
        *)
        MACHINE="$1"
        ;;
    esac
fi

#
# Machine size is based on AWS T4g ARM machine sizes
# See https://aws.amazon.com/ec2/instance-types/
#
if [ "$2" = "" ]; then
    MACHINE_SIZE="--cpus 2 --memory 8G --disk 50G"
else
    case "$2" in
        nano)
        MACHINE_SIZE="--cpus 2 --memory 512M --disk 50G"
        ;;
        micro)
        MACHINE_SIZE="--cpus 2 --memory 1G --disk 50G"
        ;;
        small)
        MACHINE_SIZE="--cpus 2 --memory 2G --disk 50G"
        ;;
        medium)
        MACHINE_SIZE="--cpus 2 --memory 4G --disk 50G"
        ;;
        large)
        MACHINE_SIZE="--cpus 2 --memory 8G --disk 50G"
        ;;
        xlarge)
        MACHINE_SIZE="--cpus 4 --memory 16G --disk 100G"
        ;;
        2xlarge)
        MACHINE_SIZE="--cpus 8 --memory 32G --disk 150G"
        ;;
    esac
fi

#
#Third cli option is what image we're using
#
if [ "$3" != "" ]; then
	IMAGE="$3"
else
	IMAGE="jammy"
fi

#
# Figure out if we're launching, starting or machine is already active
#
if multipass list | grep "$MACHINE" >/dev/null; then
    VM_STATE=$(multipass info "$MACHINE" | grep -i State)
    case "${VM_STATE}" in
        *Stopped)
        multipass start "$MACHINE"
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
		# Handle the transition from machine name "-init.yaml" to machine name dot yaml
		if [ -f "${MACHINE}-init.yaml" ]; then
        	CLOUD_INIT="${MACHINE}-init.yaml"
		else
			CLOUD_INIT="${MACHINE}.yaml"
    	fi
	fi
    echo "Launching $MACHINE";
    multipass -v launch \
		--name "${MACHINE}" \
        --cloud-init "${CLOUD_INIT}" \
		$MACHINE_SIZE \
		$IMAGE
	echo "Restart ${MACHINE}"
    multipass restart "${MACHINE}"
fi

#
# If a src directory exists mount it
#
#if [ -d src ]; then
#  multipass mount src "$MACHINE:src"
#fi

#
# If a Sites directory exists mount it
#
#if [ -d Sites ]; then
#  multipass mount Sites "$MACHINE:Sites"
#fi

#
# Include staff-favorites.bash if exists
#
if [ -f scripts/staff-favorites.bash ]; then
  multipass transfer scripts/staff-favorites.bash "$MACHINE:."
fi
#if [ -f scripts/setup-self-signed-SSL-certs.bash ]; then
#  multipass transfer scripts/setup-self-signed-SSL-certs.bash "$MACHINE:."
#fi

# 
# Display state of machine
#
multipass info "$MACHINE"
