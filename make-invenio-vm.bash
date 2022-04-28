#!/bin/bash
MACHINE="invenio"
multipass set client.primary-name="${MACHINE}"
multipass launch --name "${MACHINE}" \
    --cpus 2 --mem 4G --disk 20G \
    --cloud-init ${MACHINE}-init.yaml
multipass restart "${MACHINE}"
