#!/bin/bash ../test_wrapper.sh

require_relative './app_controller_test_base'

class ImagePullerTest < AppControllerTestBase

  # - - - - - - - - - - - - - - - - - - - - - -
  # from Language+Test setup page
  # - - - - - - - - - - - - - - - - - - - - - -

  test '406596',
  'language pull.needed is true if docker image is not pulled' do
    # AppControllerTestBase sets StubRunner
    do_get 'language_pull_needed', major_minor_js('C#', 'Moq')
    assert json['needed']
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  test 'B28A3D',
  'language pull.needed is false if docker image is pulled' do
    # AppControllerTestBase sets StubRunner
    do_get 'language_pull_needed', major_minor_js('C#', 'NUnit')
    refute json['needed']
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  test '0A8080',
  'language pull issues docker-pull image_name command and returns succeeded=true if pull succeeds' do
    setup_mock_shell
    shell.mock_exec(
      ['docker pull cyberdojofoundation/csharp_nunit'],
      docker_pull_output,
      exit_success
    )
    do_get 'language_pull', major_minor_js('C#', 'NUnit')
    assert json['succeeded']
    shell.teardown
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  test '4DB3FD',
  'language pull issues docker-pull image_name command and returns succeeded=false if pull fails' do
    setup_mock_shell
    shell.mock_exec(
      ['docker pull cyberdojofoundation/csharp_nunit'],
      any_output='456ersfdg',
      exit_failure=34
    )
    do_get 'language_pull', major_minor_js('C#', 'NUnit')
    refute json['succeeded']
    shell.teardown
  end

  # - - - - - - - - - - - - - - - - - - - - - -
  # from Custom setup page
  # - - - - - - - - - - - - - - - - - - - - - -

  test '294C10',
  'custom pull.needed is true if docker image is not pulled' do
    do_get 'custom_pull_needed', major_minor_js('Tennis refactoring', 'Python unitttest')
    assert json['needed']
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  test '9D3E9A',
  'custom pull_needed is false if docker image is pulled' do
    do_get 'custom_pull_needed', major_minor_js('Tennis refactoring', 'C# NUnit')
    refute json['needed']
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  test '4694A0',
  'custom pull issues docker-pull image_name command and returns succeeded=true if pull succeeds' do
    setup_mock_shell
    shell.mock_exec(
      ['docker pull cyberdojofoundation/python_unittest'],
      docker_pull_output,
      exit_success
    )
    do_get 'custom_pull', major_minor_js('Tennis refactoring', 'Python unitttest')
    assert json['succeeded']
    shell.teardown
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  test '05C5E7',
  'custom pull issues docker-pull image_name command and returns succeeded=false if pull fails' do
    setup_mock_shell
    shell.mock_exec(
      ['docker pull cyberdojofoundation/python_unittest'],
      any_output='sdfsdfsdf',
      exit_failure=34
    )
    do_get 'custom_pull', major_minor_js('Tennis refactoring', 'Python unitttest')
    refute json['succeeded']
    shell.teardown
  end

  private

  def do_get(route, params = {})
    controller = 'image_puller'
    get "#{controller}/#{route}", params
    assert_response :success
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def major_minor_js(major, minor)
    {
      format: :js,
       major: major,
       minor: minor
    }
  end

end
