#!/bin/bash
set -e

MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

pushd ${MY_DIR} > /dev/null

CONTEXT_DIR=.

docker build \
  --tag=cyberdojo/${PWD##*/} \
  --file=${CONTEXT_DIR}/Dockerfile \
  ${CONTEXT_DIR}

popd > /dev/null
