#!/bin/bash

# Get NPM version by Node Version
# List versions ...

echo "Node JS Version,NPM Version"
curl -s "https://nodejs.org/dist/index.json" | jsonrange -values -i - | while read OBJ; do
  NODE_VERSION=$(echo "$OBJ" | jq -r ".version")
  NPM_VERSION=$(echo "$OBJ" | jq -r ".npm")
  if [ "${NPM_VERSION}" != "null" ]; then
	  echo "$NODE_VERSION,$NPM_VERSION"
  fi
done
#curl -s "https://nodejs.org/dist/index.json" | jq -r ".[] | select(.version == \"v16.20.2\") | .npm"

