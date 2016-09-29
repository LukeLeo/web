#!/bin/bash ../test_wrapper.sh

require_relative './app_lib_test_base'

class StubRunnerTest < AppLibTestBase

  def setup
    super
    set_shell_class 'MockProxyHostShell'
    set_runner_class 'StubRunner'
  end

  def teardown
    shell.teardown
    super
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '6DFD81',
  'parent is ctor parameter' do
    assert_equal "StubRunner", runner.class.name
    assert_equal self, runner.parent
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '43E866',
  'pulled? is true only for 4 specific images' do
    assert runner.pulled? "#{cdf}/nasm_assert"
    assert runner.pulled? "#{cdf}/gcc_assert"
    assert runner.pulled? "#{cdf}/csharp_nunit"
    assert runner.pulled? "#{cdf}/gpp_cpputest"
    refute runner.pulled? "#{cdf}/csharp_moq"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '0B42BD',
  'pull issues docker-pull command to shell' do
    shell.mock_exec([sudo + "docker pull #{cdf}/csharp_moq"], output='', success)
    runner.pull "#{cdf}/csharp_moq"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '84B2C0',
  'stub_run_output stubs output for subsequent run' do
    kata = make_kata
    lion = kata.start_avatar(['lion'])
    runner.stub_run_output(lion, output='syntax error line 1')
    assert_equal output, runner.run(kata.id, 'lion', _delta=nil, _files=nil, _image_name=nil)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '180F3F',
  'stub_run_colour stubs given colour for subsequent run' do
    kata = make_kata
    lion = kata.start_avatar(['lion'])
    [:red, :amber, :green].each do |colour|
      runner.stub_run_colour(lion, colour)
      output = runner.run(kata.id, 'lion', _delta=nil, _files=nil, _image_name=nil)
      assert_equal colour.to_s, kata.red_amber_green(output)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'AF797E',
  'run without preceeding stub returns amber' do
    kata = make_kata
    lion = kata.start_avatar(['lion'])
    output = runner.run(kata.id, 'lion', _delta=nil, _files=nil, _image_name=nil)
    colour = kata.red_amber_green(output)
    assert_equal 'amber', colour
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '4B29D5',
  'stub_run_colour with bad colour raises' do
    assert_raises { runner.stub_run_colour(lion=nil, :yellow) }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '195067',
  'max_seconds is 10' do
    assert_equal 10, runner.max_seconds
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def cdf; 'cyberdojofoundation'; end
  def success; 0; end
  def sudo; 'sudo -u docker-runner sudo '; end
end
