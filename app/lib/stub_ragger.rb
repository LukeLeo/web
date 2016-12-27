require_relative '../../lib/fake_disk'

class StubRagger

  def initialize(_parent)
    @@disk ||= FakeDisk.new(self)
  end

  def stub_colour(rag)
    fail "invalid colour #{rag}" unless [:red,:amber,:green].include? rag
    dir.make
    dir.write(filename, rag)
  end

  def colour(_kata, _output)
    dir.read(filename)
  end

  private

  def filename
    'stub_colour'
  end

  def dir
    disk[test_id]
  end

  def disk
    @@disk
  end

  def test_id
    ENV['CYBER_DOJO_TEST_ID']
  end

end
