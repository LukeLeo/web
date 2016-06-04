#!/bin/sh

# TODO:
# cdf-web name is from docker-compose.yml file
# reverse this dependency so the name is passed from here.
# repeat for other similar variables.

# TODO:
# SERVER_NAME=web:${DOCKER_VERSION}
# DOCKER_HUB_USERNAME=cyberdojofoundation
# These two are always used together. Do as a single variable

if [ "${CYBER_DOJO_SCRIPT_WRAPPER}" = "" ]; then
  echo "Do not call this script directly. Use cyber-dojo (no .sh) instead"
  exit 1
fi

my_dir="$( cd "$( dirname "${0}" )" && pwd )"
docker_compose_cmd="docker-compose --file=${my_dir}/docker-compose.yml"

default_languages_volume=default_languages
default_exercises_volume=default_exercises
default_instructions_volume=default_instructions

# set environment variables required by docker-compose.yml

export DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed '$s/.$//')
export CYBER_DOJO_HOME=/usr/src/cyber-dojo

export CYBER_DOJO_KATAS_CLASS=${CYBER_DOJO_KATAS_CLASS:=HostDiskKatas}
export CYBER_DOJO_SHELL_CLASS=${CYBER_DOJO_SHELL_CLASS:=HostShell}
export CYBER_DOJO_DISK_CLASS=${CYBER_DOJO_DISK_CLASS:=HostDisk}
export CYBER_DOJO_LOG_CLASS=${CYBER_DOJO_LOG_CLASS:=StdoutLog}
export CYBER_DOJO_GIT_CLASS=${CYBER_DOJO_GIT_CLASS:=HostGit}

export CYBER_DOJO_RUNNER_CLASS=${CYBER_DOJO_RUNNER_CLASS:=DockerTarPipeRunner}
export CYBER_DOJO_RUNNER_SUDO='sudo -u docker-runner sudo'
export CYBER_DOJO_RUNNER_TIMEOUT=${CYBER_DOJO_RUNNER_TIMEOUT:=10}

export CYBER_DOJO_LANGUAGES_VOLUME=${default_languages_volume}
export CYBER_DOJO_EXERCISES_VOLUME=${default_exercises_volume}
export CYBER_DOJO_INSTRUCTIONS_VOLUME=${default_instructions_volume}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

SERVER_NAME=web:${DOCKER_VERSION}
DOCKER_HUB_USERNAME=cyberdojofoundation

one_time_creation_of_katas_data_container() {
  # ensure katas-data-container exists.
  # o) if it doesn't and /var/www/cyber-dojo/katas exists on the host
  #    then assume it holds practice sessions and _copy_ them into the new katas-data-container.
  # o) if it doesn't and /var/www/cyber-dojo/katas does not exist on the host
  #    then create new _empty_ katas-data-container

  local katas_root=/var/www/cyber-dojo/katas
  local katas_data_container=cdf-katas-DATA-CONTAINER

  docker ps --all | grep --silent ${katas_data_container}
  if [ $? != 0 ]; then
    # determine appropriate Dockerfile (to create katas-data-container)
    if [ -d "${katas_root}" ]; then
      echo "copying ${katas_root} into new ${katas_data_container}"
      SUFFIX=copied
      CONTEXT_DIR=${katas_root}
    else
      echo "creating new empty ${katas_data_container}"
      SUFFIX=empty
      CONTEXT_DIR=.
    fi

    # extract appropriate Dockerfile from web image
    local katas_dockerfile=${CONTEXT_DIR}/Dockerfile
    local cid=$(docker create ${DOCKER_HUB_USERNAME}/${SERVER_NAME})
    docker cp ${cid}:${CYBER_DOJO_HOME}/app/docker/katas/Dockerfile.${SUFFIX} \
              ${katas_dockerfile}
    docker rm -v ${cid} > /dev/null

    # 3. extract appropriate .dockerignore from web image
    local katas_docker_ignore=${CONTEXT_DIR}/.dockerignore
    local cid=$(docker create ${DOCKER_HUB_USERNAME}/${SERVER_NAME})
    docker cp ${cid}:${CYBER_DOJO_HOME}/app/docker/katas/Dockerignore.${SUFFIX} \
              ${katas_docker_ignore}
    docker rm -v ${cid} > /dev/null

    # use Dockerfile to build image
    local tag=${DOCKER_HUB_USERNAME}/katas
    docker build \
             --build-arg=CYBER_DOJO_KATAS_ROOT=${CYBER_DOJO_HOME}/katas \
             --tag=${tag} \
             --file=${katas_dockerfile} \
             ${CONTEXT_DIR}

    # use image to create data-container
    docker create \
           --name ${katas_data_container} \
           ${tag} \
           echo 'cdfKatasDC'

    rm ${katas_dockerfile}
    rm ${katas_docker_ignore}
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

cyber_dojo_rb() {
  docker run \
    --rm \
    --user=root \
    --env=DOCKER_VERSION=${DOCKER_VERSION} \
    --volume=/var/run/docker.sock:/var/run/docker.sock \
    ${DOCKER_HUB_USERNAME}/${SERVER_NAME} \
    ${CYBER_DOJO_HOME}/app/docker/cyber-dojo.rb $1
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

volume_create() {
  local name=$1
  local url=$2
  cyber_dojo_rb "volume create --name=${name} --git=${url}"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

volume_exists() {
  # careful to not match substring
  local space=' '
  local end_of_line='$'
  docker volume ls | grep --silent "${space}${1}${end_of_line}"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

cyber_dojo_down() {
  ${docker_compose_cmd} down
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

cyber_dojo_sh() {
  # cdf-web name is from docker-compose.yml file
  docker exec --interactive --tty cdf-web sh
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

cyber_dojo_up() {
  # process volume arguments
  shift
  for arg in "$*"
  do
    # eg --exercises=james
    local name=$(echo ${arg} | cut -f1 -s -d=)
    local volume=$(echo ${arg} | cut -f2 -s -d=)

    if [ "${name}" = "--languages" ] && [ "${volume}" != "" ]; then
      export CYBER_DOJO_LANGUAGES_VOLUME=${volume}
    fi

    if [ "${name}" = "--exercises" ] && [ "${volume}" != "" ]; then
      export CYBER_DOJO_EXERCISES_VOLUME=${volume}
    fi

    if [ "${name}" = "--instructions" ] && [ "${volume}" != "" ]; then
      export CYBER_DOJO_INSTRUCTIONS_VOLUME=${volume}
    fi
  done

  # create default volumes if necessary
  local github_jon_jagger='https://github.com/JonJagger'

  if [ "${CYBER_DOJO_LANGUAGES_VOLUME}" = "${default_languages_volume}" ]; then
    if ! volume_exists ${default_languages_volume}; then
      volume_create ${default_languages_volume} "${github_jon_jagger}/cyber-dojo-languages.git"
    fi
  fi

  if [ "${CYBER_DOJO_EXERCISES_VOLUME}" = "${default_exercises_volume}" ]; then
    if ! volume_exists ${default_exercises_volume}; then
      volume_create ${default_exercises_volume} "${github_jon_jagger}/cyber-dojo-refactoring-exercises.git"
    fi
  fi

  if [ "${CYBER_DOJO_INSTRUCTIONS_VOLUME}" = "${default_instructions_volume}" ]; then
    if ! volume_exists ${default_instructions_volume}; then
      volume_create ${default_instructions_volume} "${github_jon_jagger}/cyber-dojo-instructions.git"
    fi
  fi

  # - - - - - - - - - - - - - - -
  if ! volume_exists ${CYBER_DOJO_LANGUAGES_VOLUME}; then
    echo "volume ${CYBER_DOJO_LANGUAGES_VOLUME} does not exist"
    exit 1
  fi

  if ! volume_exists ${CYBER_DOJO_EXERCISES_VOLUME}; then
    echo "volume ${CYBER_DOJO_EXERCISES_VOLUME} does not exist"
    exit 1
  fi

  if ! volume_exists ${CYBER_DOJO_INSTRUCTIONS_VOLUME}; then
    echo "volume ${CYBER_DOJO_INSTRUCTIONS_VOLUME} does not exist"
    exit 1
  fi

  # bring up server with volumes
  echo "Using volume languages=${CYBER_DOJO_LANGUAGES_VOLUME}"
  echo "Using volume exercises=${CYBER_DOJO_EXERCISES_VOLUME}"
  echo "Using volume instructions=${CYBER_DOJO_INSTRUCTIONS_VOLUME}"
  ${docker_compose_cmd} up -d
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

one_time_creation_of_katas_data_container

cyber_dojo_rb "$*"
if [ $? != 0  ]; then
  exit 1
fi

if [ "$1" = "up" ]; then
  cyber_dojo_up $@
fi

if [ "$1" = "sh" ]; then
  cyber_dojo_sh
fi

if [ "$1" = "down" ]; then
  cyber_dojo_down
fi

