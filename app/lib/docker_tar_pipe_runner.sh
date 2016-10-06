#!/bin/sh

# A runner that tar-pipes files from the avatar's sandbox into and out of
# of the test-run container, regardless of whether the avatar's sandbox comes
# from a host-disk [volume] or a data-container [volumes_from].

SRC_DIR=$1     # Where the source files are
IMAGE=$2       # What they'll run in, eg cyberdojofoundation/gcc_assert
MAX_SECS=$3    # How long they've got to complete in seconds, eg 10
SUDO=$4        # sudo incantation for docker commands

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 1. Start the container running
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   --detach       ; get the CID for [sleep && docker rm] before [docker exec]
#   --interactive  ; we tar-pipe later
# For security...
#   --net=none
#   --pids-limit (prevent fork bombs)
#   --security-opt=no-new-privileges
#   --user=nobody

CID=$(${SUDO} docker run --detach \
                         --interactive \
                         --net=none \
                         --pids-limit=64 \
                         --security-opt=no-new-privileges \
                         --user=nobody \
                         ${IMAGE} sh)

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 2. Tar-pipe the src-files into the container's sandbox
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# http://blog.extracheese.org/2010/05/the-tar-pipe.html
#
# o) The LHS end of the pipe...
#
#      [tar -zcf]  create a compressed tar file
#             [-]  don't write to a named file but to STDOUT
#             [.]  tar the current directory
#                    which is why there's a preceding cd
#
# o) The RHS end of the pipe...
#
#           [tar -zxf]   extract files from the compressed tar file
#                  [-]   don't read from a named file but from STDIN
#      [-C ${SANDBOX}]   save the extracted files to the ${SANDBOX} directory
#                           which is why there's a preceding mkdir
#
# o) The tar-pipe has to be this...
#      (cd ${SRC_DIR} && tar -zcf - .) | ${SUDO} docker exec ...
#    it cannot be this...
#      tar -zcf - ${SRC_DIR} | ${SUDO} docker exec ...
#    because that retains the full path of each file.
#
# o) chown -R nobody ${SANDBOX} \
#    && usermod --home ${SANDBOX} nobody"
#
#    The existing C#-NUnit image picks up HOME from the *current* user.
#    By default, nobody's entry in /etc/passwd is
#       nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
#    and nobody does not have a home dir.
#    I usermod to solve this. The C#-NUnit docker image is built
#    from an Ubuntu base which has usermod.
#    Of course, the usermod runs if you are not using C#-NUnit too.
#    In particular usermod is not installed in a default Alpine linux.
#    It's in the shadow package.
#
# o) The F#-NUnit cyber-dojo.sh names the /sandbox folder
#    So SANDBOX has to be /sandbox for backward compatibility.
#    F#-NUnit is the only cyber-dojo.sh that names /sandbox.

SANDBOX=/sandbox

(cd ${SRC_DIR} && tar -zcf - .) \
  | ${SUDO} docker exec \
                   --user=root \
                   --interactive \
                   ${CID} \
                   sh -c "mkdir ${SANDBOX} \
                       && tar -zxf - -C ${SANDBOX} \
                       && chown -R nobody ${SANDBOX} \
                       && usermod --home ${SANDBOX} nobody 2> /dev/null"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 3. After max_seconds, remove the container
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# o) Doing [docker stop ${CID}] is not enough to stop a container
#    that is printing in an infinite loop (for example).
#
# o) Any zombie processes this backgrounded process creates are reaped by tini.
#    See top of app/docker/web/Dockerfile
#
# o) The parentheses puts the commands into a child process.
#
# o) The trailing & backgrounds it.
#
# o) Piping stdout and stderr of both sub-commands (&>) to dev/null ensures
#    that normal shell output [Terminated] from the pkill (6) is suppressed.

(sleep ${MAX_SECS} &> /dev/null && ${SUDO} docker rm --force ${CID} &> /dev/null) &
SLEEP_DOCKER_RM_PID=$!

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 4. Run cyber-dojo.sh
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

OUTPUT=$(${SUDO} docker exec \
               --user=nobody \
               --interactive \
               ${CID} \
               sh -c "cd ${SANDBOX} && ./cyber-dojo.sh 2>&1")

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 5. Don't use the exit-status of cyber-dojo.sh
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Using it to determine red/amber/green status is unreliable
#   - not all test frameworks set their exit-status properly
#   - cyber-dojo.sh is editable (suppose it ended [exit 137])

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 6. If the sleep-docker-rm process (3) is still alive race to
#    kill it before it does [docker rm ${CID}]
#      pkill   == kill processes
#      -P PID  == whose parent pid is PID
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

pkill -P ${SLEEP_DOCKER_RM_PID}
if [ "$?" != "0" ]; then
  # Failed to kill the sleep-docker-rm process
  # Assume [docker rm ${CID}] happened
  ${SUDO} docker rm --force ${CID} &> /dev/null # belt and braces
  exit 137 # (128=timed-out) + (9=killed)
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 7. Check the CID container is still running (belt and braces)
#    We're aiming for
#      - the background 10-second kill process is dead
#      - the test-run container is still alive
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

RUNNING=$(${SUDO} docker inspect --format="{{ .State.Running }}" ${CID})
if [ "${RUNNING}" != "true" ]; then
  exit 137 # (128=timed-out) + (9=killed)
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 8. We're not using the exit status (5) of the test container
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   Instead
#     - echo the output so it can be red/amber/green regex'd (see 5)
#     - tar-pipe *everything* out of the run-container's sandbox back to SRC_DIR
#     - remove the container
#     - exit 0

echo "${OUTPUT}"

# The command [ find . -mindepth 1 -delete] deletes all files (including dot files)
# and subdirs. This is so the transfer of files is always 'total' in both
# directions. That is, from the katas subdir into the test-run-container,
# and from the test-run-container back into the katas subdir.
# Eg., See test/app_controllers/kata_test.rb - test 'E77261'

${SUDO} docker exec \
               --user=root \
               --interactive \
               ${CID} \
               sh -c "cd ${SANDBOX} && tar -zcf - ." \
               | (cd ${SRC_DIR} && find . -mindepth 1 -delete && tar -zxf - .)

${SUDO} docker rm --force ${CID} &> /dev/null

exit 0
