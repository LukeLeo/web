
# A runner whose access to the avatar's source files is via a data-container
# containing files for *all* katas/... sub folders.
#
# o) A test-run saves the *changed* visible-files to the avatar's katas/id/ sub-folder.
# o) The shell file then
#     - tar-pipes all of katas/id/ from the data-container into the run-containers /sandbox
#     - executes cyber-dojo.sh in the run-container's sandbox
#     - tar-pipes all of the run-container's /sandbox back to katas/id/ in the data-container
#
# o) State is retained across tests.
# o) Untouched files retain the same date-time stamp.
# o) cyber-dojo.sh can do incremental makes.
#
# The tar-piping is to isolate the avatar's sub-dir in the katas-data-container.

class DockerTarPipeRunner

  def initialize(dojo)
    @dojo = dojo
  end

  # queries

  def parent
    @dojo
  end

  # modifiers

  def pulled?(image_name)
    image_names.include?(image_name)
  end

  def run(avatar, delta, files, image_name)
    sandbox = avatar.sandbox
    katas.sandbox_save(sandbox, delta, files)
    katas_sandbox_path = katas.path_of(sandbox)
    max_seconds = parent.env('runner_timeout')
    # See sudo comments in docker/web/Dockerfile
    sudo = parent.env('runner_sudo')
    args = [ katas_sandbox_path, image_name, max_seconds, quoted(sudo) ].join(space = ' ')
    output, exit_status = shell.cd_exec(path, "./docker_tar_pipe_runner.sh #{args}")
    output_or_timed_out(output, exit_status, max_seconds)
  end

  private

  include DockerRunner

  def quoted(s)
    "'" + s + "'"
  end

end
