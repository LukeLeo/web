require_relative 'lib_test_base'

class LogMemoryTest < LibTestBase

  test '3F6D7F',
  'log is initially empty' do
    log = LogMemory.new(dummy = nil)
    refute log.include? 'anything'
    assert_equal '[]', log.to_s
  end

  # - - - - - - - - - - - - - - -

  test '734E69',
  'log contains inserted message' do
    log = LogMemory.new(dummy = nil)
    log << 'something'
    assert log.include? 'something'
    assert_equal '["something"]', log.to_s
  end

end
