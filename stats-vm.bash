#!/bin/bash
if [ "$1" = "" ]; then
    MACHINE=$(multipass get client.primary-name)
else
    MACHINE="$1"
fi
multipass info $MACHINE
