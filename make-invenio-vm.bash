#!/bin/bash
MACHINE="invenio"
multipass set client.primary-name="${MACHINE}"
multipass launch --name "${MACHINE}" \
    --cpus 2 --mem 6G --disk 50G \
    --cloud-init ${MACHINE}-init.yaml
multipass restart "${MACHINE}"
