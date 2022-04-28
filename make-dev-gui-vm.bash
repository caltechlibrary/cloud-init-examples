#!/bin/bash
MACHINE="dev-gui"
multipass set client.primary-name="${MACHINE}"
multipass launch --name "${MACHINE}" \
    --cpus 4 --mem 8G --disk 50G \
    --cloud-init ${MACHINE}-init.yaml
multipass restart "${MACHINE}"


