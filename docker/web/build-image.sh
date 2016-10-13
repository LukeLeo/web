#!/bin/sh
set -e

# A docker-client binary is installed *inside* the web image
# This creates a dependency on the docker-version installed
# on the host. Thus, the web Dockerfile accepts the docker-version
# to install as a parameter, and the built web image is tagged with
# this version number.
DOCKER_VERSION=${1:-1.12.1}

# The 'home' directory inside the web image.
# It's parameterized to avoid duplication.
CYBER_DOJO_HOME=${2:-/usr/src/cyber-dojo}

MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

CONTEXT_DIR=${MY_DIR}/../..

cat ${MY_DIR}/Dockerfile | sed "1 s/DOCKER_VERSION/${DOCKER_VERSION}/" > ${CONTEXT_DIR}/Dockerfile
cp ${MY_DIR}/.dockerignore  ${CONTEXT_DIR}

docker build \
  --build-arg=CYBER_DOJO_HOME=${CYBER_DOJO_HOME} \
  --tag=cyberdojo/${PWD##*/}:${DOCKER_VERSION} \
  --file=${CONTEXT_DIR}/Dockerfile \
  ${CONTEXT_DIR}

rm ${CONTEXT_DIR}/Dockerfile
rm ${CONTEXT_DIR}/.dockerignore
