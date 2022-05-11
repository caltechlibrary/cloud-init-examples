#!/bin/bash
if [ "$1" = "" ]; then
    MACHINE=$(multipass get client.primary-name)
else
    MACHINE="$1"
fi
multipass unmount $MACHINE
multipass stop $MACHINE
multipass info $MACHINE
