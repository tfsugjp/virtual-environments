#!/bin/bash -e
################################################################################
##  File:  docker-compose.sh
##  Desc:  Installs Docker Compose
################################################################################

# Install docker-compose v1 from releases
URL="https://github.com/docker/compose/releases/download/v2.22.0/docker-compose-linux-aarch64"
curl -fsSL $URL -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

invoke_tests "Tools" "Docker-compose v1"
