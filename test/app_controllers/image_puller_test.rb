require_relative './app_controller_test_base'

class ImagePullerTest < AppControllerTestBase

  def setup_mock_shell
    set_shell_class('MockHostShell')
  end

  # Note: test_hex_id_helpers.setup_id(hex) sets StubRunner
  # which assumes the current state of [docker images] to be
  #    cyberdojofoundation/nasm_assert
  #    cyberdojofoundation/gcc_assert
  #    cyberdojofoundation/csharp_nunit
  #    cyberdojofoundation/gpp_cpputest

  # - - - - - - - - - - - - - - - - - - - - - -
  # from Language+Test setup page
  # - - - - - - - - - - - - - - - - - - - - - -

  test '406596',
  'language pull.needed is true when docker image is not pulled' do
    do_get 'pull_needed', major_minor_js('language', 'C#', 'Moq')
    assert json['needed']
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  test '406A3D',
  'language pull.needed is false when docker image is pulled' do
    do_get 'pull_needed', major_minor_js('language', 'C#', 'NUnit')
    refute json['needed']
  end

  # - - - - - - - - - - - - - - - - - - - - - -
=begin
  test '406080',
  'language pull issues docker-pull image_name command',
  'and returns succeeded=true when pull succeeds' do
    setup_mock_shell
    mock_docker_pull_success('csharp_nunit')
    do_get 'pull', major_minor_js('language', 'C#', 'NUnit')
    assert json['succeeded']
    shell.teardown
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  test '4063FD',
  'language pull issues docker-pull image_name command',
  'and returns succeeded=false when pull fails' do
    setup_mock_shell
    mock_docker_pull_failure('csharp_nunit')
    do_get 'pull', major_minor_js('language', 'C#', 'NUnit')
    refute json['succeeded']
    shell.teardown
  end
=end

  # - - - - - - - - - - - - - - - - - - - - - -
  # from Custom setup page
  # - - - - - - - - - - - - - - - - - - - - - -

  test '406C10',
  'custom pull.needed is true when docker image is not pulled' do
    do_get 'pull_needed', major_minor_js('custom', 'Tennis refactoring', 'Python unitttest')
    assert json['needed']
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  test '406E9A',
  'custom pull_needed is false when docker image is pulled' do
    do_get 'pull_needed', major_minor_js('custom', 'Tennis refactoring', 'C# NUnit')
    refute json['needed']
  end

  # - - - - - - - - - - - - - - - - - - - - - -
=begin
  test '4064A0',
  'custom pull issues docker-pull image_name command',
  'and returns succeeded=true when pull succeeds' do
    setup_mock_shell
    mock_docker_pull_success('python_unittest')
    do_get 'pull', major_minor_js('custom', 'Tennis refactoring', 'Python unitttest')
    assert json['succeeded']
    shell.teardown
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  test '4065E7',
  'custom pull issues docker-pull image_name command',
  'and returns succeeded=false when pull fails' do
    setup_mock_shell
    mock_docker_pull_failure('python_unittest')
    do_get 'pull', major_minor_js('custom', 'Tennis refactoring', 'Python unitttest')
    refute json['succeeded']
    shell.teardown
  end
=end

  # - - - - - - - - - - - - - - - - - - - - - -
  # from Fork on review page/dialog
  # - - - - - - - - - - - - - - - - - - - - - -

  test '406269',
  'kata pull.needed is false when image (from post start-point re-architecture)',
  'kata.id has already been pulled' do
    create_kata('C#, NUnit')
    do_get 'pull_needed', id_js
    refute json['needed']
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  test '406A97',
  'kata pull.needed is true when image (from post start-point re-architecture)',
  'kata.id has not been pulled' do
    create_kata('C#, Moq')
    do_get 'pull_needed', id_js
    assert json['needed']
  end

  # - - - - - - - - - - - - - - - - - - - - - -
=begin
  test '406E66',
  'kata pull issues docker-pull image_name command',
  'and returns succeeded=true when pull succeeds' do
    create_kata('C#, Moq')
    mock_docker_pull_success('csharp_moq')
    do_get 'pull', id_js
    assert json['succeeded']
    shell.teardown
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  test '406B07',
  'kata pull issues docker-pull image_name command',
  'and returns succeeded=false when pull fails' do
    create_kata('C#, Moq')
    mock_docker_pull_failure('csharp_moq')
    do_get 'pull', id_js
    refute json['succeeded']
    shell.teardown
  end
=end

  private

  def mock_docker_pull_failure(image_name)
    setup_mock_shell
    shell.mock_exec(
      [sudo + "docker pull cyberdojofoundation/#{image_name}"],
      any_output='456ersfdg',
      exit_failure=34
    )
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def mock_docker_pull_success(image_name)
    setup_mock_shell
    shell.mock_exec(
      [sudo + "docker pull cyberdojofoundation/#{image_name}"],
      docker_pull_output,
      exit_success
    )
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def do_get(route, params = {})
    controller = 'image_puller'
    get "#{controller}/#{route}", params
    assert_response :success
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def major_minor_js(type, major, minor)
    {
      format: :js,
        type: type,
       major: major,
       minor: minor
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def id_js
    {
        type: :kata,
      format: :js,
          id: @id
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def sudo
    'sudo -u docker-runner sudo '
  end

end
