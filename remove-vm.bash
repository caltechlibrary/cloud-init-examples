#!/bin/bash
function usage() {
    APP_NAME=$(basename $0)
    cat<<EOT
NAME
   ${APP_NAME}

SYSNOPSIS

   ${APP_NAME}  VM_NAME

DESCRIPTION

Delete and purge a multipass VM instance.

If the VM_NAME is "all" then all VMs will be deleted
and purged.

EOT
}

if [ "$1" = "" ]; then
    usage
    exit 1
else
    MACHINE="$1"
fi
if [ "$MACHINE" = "all" ]; then
	multipass delete --all && multipass purge
else
	multipass delete $MACHINE && multipass purge
fi
