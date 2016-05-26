#!/bin/sh

if [ "${CYBER_DOJO_SCRIPT_WRAPPER}" = "" ]; then
  echo "Do not call this script directly. Use cyber-dojo (no .sh) instead"
  exit 1
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# ensure katas-data-container exists.
# o) if it doesn't and /var/www/cyber-dojo/katas exists on the host
#    then assume it holds practice sessions and _copy_ them into the new katas-data-container.
# o) if it doesn't and /var/www/cyber-dojo/katas does not exist on the host
#    then create new _empty_ katas-data-container

KATAS_ROOT=/var/www/cyber-dojo/katas
KATAS_DATA_CONTAINER=cdf-katas-DATA-CONTAINER

docker ps -a | grep -q ${KATAS_DATA_CONTAINER}
if [ $? != 0 ]; then
  # 1. determine appropriate Dockerfile (to create katas-data-container)
  if [ -d "${KATAS_ROOT}" ]; then
    echo "copying ${KATAS_ROOT} into new ${KATAS_DATA_CONTAINER}"
    SUFFIX=copied
    CONTEXT_DIR=${KATAS_ROOT}
  else
    echo "creating new empty ${KATAS_DATA_CONTAINER}"
    SUFFIX=empty
    CONTEXT_DIR=.
  fi

  # 2. extract appropriate Dockerfile from web image
  KATAS_DOCKERFILE=${CONTEXT_DIR}/Dockerfile
  CID=$(docker create ${DOCKER_HUB_USERNAME}/${SERVER_NAME})
  docker cp ${CID}:${CYBER_DOJO_HOME}/app/docker/katas/Dockerfile.${SUFFIX} \
            ${KATAS_DOCKERFILE}
  docker rm -v ${CID} > /dev/null

  # 3. extract appropriate .dockerignore from web image
  KATAS_DOCKERIGNORE=${CONTEXT_DIR}/.dockerignore
  CID=$(docker create ${DOCKER_HUB_USERNAME}/${SERVER_NAME})
  docker cp ${CID}:${CYBER_DOJO_HOME}/app/docker/katas/Dockerignore.${SUFFIX} \
            ${KATAS_DOCKERIGNORE}
  docker rm -v ${CID} > /dev/null

  # 4. use Dockerfile to build image
  TAG=${DOCKER_HUB_USERNAME}/katas
  docker build \
           --build-arg=CYBER_DOJO_KATAS_ROOT=${CYBER_DOJO_HOME}/katas \
           --tag=${TAG} \
           --file=${KATAS_DOCKERFILE} \
           ${CONTEXT_DIR}

  # 5. use image to create data-container
  docker create \
         --name ${KATAS_DATA_CONTAINER} \
         ${TAG} \
         echo 'cdfKatasDC'
fi

: <<'BLOCK_COMMENT'
# Commented out because the call to cyber-dojo.rb inside the web container
# relies on volume mounting the languages folder. Simplest option here
# is to only allow the command when the web server is already running
# and shells into it.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# ensure CYBER_DOJO_DATA_ROOT env-var is set

if [ -z "${CYBER_DOJO_DATA_ROOT}" ]; then
    echo "CYBER_DOJO_DATA_ROOT env-var is not set"
    exit 1
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# delegate to ruby script inside web image

docker run \
  --rm \
  --user=root \
  --env=DOCKER_VERSION=${DOCKER_VERSION} \
  --volume=/var/run/docker.sock:/var/run/docker.sock \
  --volume=${CYBER_DOJO_DATA_ROOT}/languages:${CYBER_DOJO_HOME}/app/data/languages:ro \
  ${DOCKER_HUB_USERNAME}/${SERVER_NAME} \
  ${CYBER_DOJO_HOME}/app/docker/cyber-dojo.rb $@

BLOCK_COMMENT

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set environment variables required by docker-compose.yml

export CYBER_DOJO_KATAS_CLASS=${CYBER_DOJO_KATAS_CLASS:=HostDiskKatas}
export CYBER_DOJO_SHELL_CLASS=${CYBER_DOJO_SHELL_CLASS:=HostShell}
export CYBER_DOJO_DISK_CLASS=${CYBER_DOJO_DISK_CLASS:=HostDisk}
export CYBER_DOJO_LOG_CLASS=${CYBER_DOJO_LOG_CLASS:=StdoutLog}
export CYBER_DOJO_GIT_CLASS=${CYBER_DOJO_GIT_CLASS:=HostGit}

export CYBER_DOJO_RUNNER_CLASS=${CYBER_DOJO_RUNNER_CLASS:=DockerTarPipeRunner}
export CYBER_DOJO_RUNNER_SUDO='sudo -u docker-runner sudo'
export CYBER_DOJO_RUNNER_TIMEOUT=${CYBER_DOJO_RUNNER_TIMEOUT:=10}

ME="./$( basename ${0} )"
MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

DOCKER_COMPOSE_CMD="docker-compose --file=${MY_DIR}/${DOCKER_COMPOSE_FILE}"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# bring up the web server's container

if [ "$1" = "up" ]; then
  # TODO: loop for multiple args, eg [exercises=URL languages=URL]
  SPEC_DC=$2
  SPEC=$(echo ${SPEC_DC} | cut -f1 -s -d=)
  DC=$(echo ${SPEC_DC} | cut -f2 -s -d=)

  if [ "${SPEC}" = "exercises" ] && [ "${DC}" != "" ]; then
    # TODO: DC = "" --> diagnostic
    export CYBER_DOJO_EXERCISES_DC=${DC}
  fi
  # TODO: set default exercises DC if none is specified

  if [ "${SPEC}" = "languages" ] && [ "${DC}" != "" ]; then
    # TODO: DC = "" --> diagnostic
    export CYBER_DOJO_LANGUAGES_DC=${DC}
  fi
  # TODO: set default exercises DC if none is specified

  ${DOCKER_COMPOSE_CMD} up -d
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# bring down the web server's container

if [ "$*" = "down" ]; then
  ${DOCKER_COMPOSE_CMD} down
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# restart the web server's container

if [ "$*" = "restart" ]; then
  # TODO: logically I guess this also needs to handle optional [exercises=DC] arguments
  ${DOCKER_COMPOSE_CMD} down
  ${DOCKER_COMPOSE_CMD} up -d
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# shell into the web container

if [ "$*" = "sh" ]; then
  # cdf-web name is from docker-compose.yml file
  docker exec --interactive --tty cdf-web sh
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# create an exercises-data-container

if [ "$1" = "exercises" ]; then
  NAME_URL=$2
  NAME=$(echo ${NAME_URL} | cut -f1 -s -d=)
  URL=$(echo ${NAME_URL} | cut -f2 -s -d=)
  if [ "${NAME}" = "" ] || [ "${URL}" = "" ]; then
    # TODO: decent diagnostic
    echo ./cyber-dojo exercises NAME=URL
    exit 1
  fi
  docker volume create --name=${NAME}
  CONTEXT_DIR=${CYBER_DOJO_HOME}/app/data/exercises
  docker run --rm -v ${NAME}:${CONTEXT_DIR} cyberdojofoundation/user-base sh -c \
    "git clone --depth 1 ${URL} ${CONTEXT_DIR}"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# create a languages-data-container
# TODO

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -

