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


EOT
}

if [ "$1" = "" ]; then
    usage
    exit 1
else
    MACHINE="$1"
fi
multipass delete $MACHINE && multipass purge
