#!/bin/bash
MACHINE="invenio"
multipass set client.primary-name="${MACHINE}"
multipass launch --name "${MACHINE}" \
    --cpus 2 --mem 2G --disk 20G \
    --cloud-init ${MACHINE}-init.yaml
multipass restart "${MACHINE}"


