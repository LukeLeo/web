require_relative './../../lib/fake_disk'
require 'json'

class FakeStorer

  def initialize(_parent)
    # This is @@disk and not @disk so that it behaves as
    # a real disk on tests that run across multiple threads
    # (as some app-controller tests do).
    @@disk ||= FakeDisk.new(self)
    # Isolate tests from each other.
    test_id = ENV['CYBER_DOJO_TEST_ID']
    @path = "/tmp/cyber-dojo/#{test_id}/katas"
  end

  attr_reader :path

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def completed(id)
    if !id.nil? && id.length >= 6
      # outer-dir has 2-characters
      outer_dir = disk[dir_join(path, outer(id))]
      if outer_dir.exists?
        # inner-dir has 8-characters
        dirs = outer_dir.each_dir.select { |inner_dir|
          inner_dir.start_with?(inner(id))
        }
        id = outer(id) + dirs[0] if dirs.length == 1
      end
    end
    id || ''
  end

  def completions(outer_dir)
    return [] unless disk[dir_join(path, outer_dir)].exists?
    disk[dir_join(path, outer_dir)].each_dir.collect { |dir| dir }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def create_kata(manifest)
    dir = kata_dir(manifest[:id])
    dir.make
    dir.write(manifest_filename, JSON.unparse(manifest))
  end

  def kata_manifest(id)
    JSON.parse(kata_dir(id).read(manifest_filename))
  end

  # - - - - - - - - - - - - - - - -

  def start_avatar(id, avatar_names)
    valid_names = avatar_names & Avatars.names
    # Don't do the & with operands swapped - you lose randomness
    name = valid_names.detect { |name| avatar_dir(id, name).make }
    return nil if name.nil? #full!
    write_avatar_increments(id, name, [])
    return name
  end

  def started_avatars(id)
    started = kata_dir(id).each_dir.collect { |name| name }
    started & Avatars.names
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_ran_tests(id, name, files, now, output, colour)
    increments = read_avatar_increments(id, name)
    tag = increments.length + 1
    increments << { 'colour' => colour, 'time' => now, 'number' => tag }
    write_avatar_increments(id, name, increments)

    files = files.clone
    files['output'] = output
    write_tag_files(id, name, tag, files)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_increments(id, name)
    tag0 =
      {
        'event' => 'created',
        'time' => kata_manifest(id)['created'],
        'number' => 0
      }
    [tag0] + read_avatar_increments(id, name)
  end

  def avatar_visible_files(id, name)
    rags = read_avatar_increments(id, name)
    tag = rags == [] ? 0 : rags[-1]['number']
    tag_visible_files(id, name, tag)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def tag_visible_files(id, name, tag)
    if tag == 0
      kata_manifest(id)['visible_files']
    else
      read_tag_files(id, name, tag)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_dir(id)
    disk[kata_path(id)]
  end

  private

  def disk
    @@disk
  end

  include IdSplitter

  def kata_path(id)
    dir_join(path, outer(id), inner(id))
  end

  def avatar_path(id, name)
    dir_join(kata_path(id), name)
  end

  def tag_path(id, name, tag)
    dir_join(avatar_path(id, name), tag.to_s)
  end

  def avatar_dir(id, name)
    disk[avatar_path(id, name)]
  end

  def tag_dir(id, name, tag)
    disk[tag_path(id, name, tag)]
  end

  def dir_join(*args)
    File.join(*args)
  end

  # - - - - - - - - - - - - - - - -

  def write_avatar_increments(id, name, increments)
    dir = avatar_dir(id, name)
    dir.write(increments_filename, JSON.unparse(increments))
  end

  def read_avatar_increments(id, name)
    dir = avatar_dir(id, name)
    JSON.parse(dir.read(increments_filename))
  end

  def increments_filename
    'increments.json'
  end

  # - - - - - - - - - - - - - - - -

  def write_tag_files(id, name, tag, files)
    dir = tag_dir(id, name, tag)
    dir.make
    dir.write(manifest_filename, JSON.unparse(files))
  end

  def read_tag_files(id, name, tag)
    dir = tag_dir(id, name, tag)
    JSON.parse(dir.read(manifest_filename))
  end

  def manifest_filename
    'manifest.json'
  end

  # - - - - - - - - - - - - - - - -

  def valid?(id)
    id.class.name == 'String' &&
      id.length == 10 &&
        id.chars.all? { |char| hex?(char) }
  end

  def hex?(char)
    '0123456789ABCDEF'.include?(char)
  end

  def kata_exists?(id)
    valid?(id) && kata_dir(id).exists?
  end

  def avatar_exists?(id, name)
    avatar_dir(id, name).exists?
  end

end
