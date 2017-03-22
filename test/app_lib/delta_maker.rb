
class DeltaMaker

  include FileDeltaMaker

  def initialize(avatar)
    @avatar = avatar
    @was = avatar.visible_files
    @now = avatar.visible_files
  end

  attr_reader :was, :now

  def file?(filename)
    @now.keys.include?(filename)
  end

  def content(filename)
    @now[filename]
  end

  def new_file(filename, content)
    refute { file?(filename) }
    @now[filename] = content
  end

  def delete_file(filename)
    assert { file?(filename) }
    @now.delete(filename)
  end

  def change_file(filename, content)
    assert { file?(filename) }
    refute { @now[filename] == content }
    @now[filename] = content
  end

  def stub_colour(colour)
    ragger.stub_colour(colour)
    @stubbed = true
  end

  def run_test(at = time_now)
    visible_files = now
    delta = make_delta(@was, @now)
    stub_colour(:red) if @stubbed.nil?
    stdout,stderr,status,colour = @avatar.test(delta, visible_files, max_seconds)
    colour ||= ragger.colour(@avatar.kata.id, stdout, stderr)
    output = stdout + stderr
    @avatar.tested(visible_files, at, output, colour)
    [delta, visible_files, output]
  end

  def test_args
    [delta, visible_files]
  end

  def delta
    make_delta(@was, @now)
  end

  def visible_files
    now
  end

  def max_seconds
    10
  end

  private

  include TimeNow

  def assert(&pred)
    fail RuntimeError.new('DeltaMaker.assert') unless pred.call
  end

  def refute(&pred)
    fail RuntimeError.new('DeltaMaker.refute') if pred.call
  end

  include NearestAncestors
  def ragger; nearest_ancestors(:ragger, @avatar); end

end
