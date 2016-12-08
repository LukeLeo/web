#!/bin/bash ../test_wrapper.sh

require_relative './app_lib_test_base'
require_relative './../../app/lib/fake_storer'

class FakeStorerTest < AppLibTestBase

  def storer
    @storer ||= FakeStorer.new(self)
  end

  def create_kata(kata_id)
    manifest = make_manifest(kata_id)
    storer.create_kata(manifest)
  end

  def kata_exists?(kata_id)
    storer.kata_exists?(kata_id)
  end

  def kata_manifest(kata_id)
    storer.kata_manifest(kata_id)
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # katas.create_kata()
  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '9D3603E8',
  'after create_kata() kata exists and manifest file holds kata properties' do
    kata_id = '603E8BAEDF'
    manifest = make_manifest(kata_id)
    storer.create_kata(manifest)
    assert kata_exists?(kata_id)
    assert_equal manifest, kata_manifest(kata_id)
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # katas.kata_exists?(id)
  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '9D3DE636',
  'kata_exists?(id) for id that is not a 10-digit string is false' do
    not_string = Object.new
    refute kata_exists?(not_string)
    nine = 'DE6369A32'
    assert_equal 9, nine.length
    refute kata_exists?(nine)
  end

  test '9D3DB6ED',
  'kata.exists?(id) for 10 digit id with non hex-chars is false' do
    has_a_g = '123456789G'
    assert_equal 10, has_a_g.length
    refute kata_exists?(has_a_g)
  end

  test '9D3CF9F2',
  'kata.exists?(id) for non-existing id is false' do
    kata_id = '9D3CF9F23D'
    assert_equal 10, kata_id.length
    refute kata_exists?(kata_id)
  end

  test '9D3DFB05',
  'kata.exists?(id) if kata with existing id is true' do
    kata_id = '9D3DFB0532'
    create_kata(kata_id)
    assert kata_exists?(kata_id)
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # katas.each()
  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def all_ids
    ids = []
    (0..255).map{|n| '%02X' % n}.each do |outer|
      storer.completions(outer).each do |inner|
        ids << (outer + inner)
      end
    end
    ids
  end

  test '9D33DFAF',
  'each() yields empty array when there are no katas' do
    assert_equal [], all_ids
  end

  test '9D35A293',
  'each() yields one kata-id' do
    kata_id = '9D35A29321'
    create_kata(kata_id)
    assert_equal [kata_id], all_ids
  end

  test '9D3F0C15',
  'each() yields two unrelated kata-ids' do
    kata_id_1 = 'C56C6C4202'
    create_kata(kata_id_1)
    kata_id_2 = 'DEB3E1325D'
    create_kata(kata_id_2)
    assert_equal [kata_id_1, kata_id_2].sort, all_ids.sort
  end

=begin

  test '29DFD1',
  'each() yields several kata-ids with common first two characters' do
    id = 'ABCDE1234'
    assert_equal 10-1, id.length
    kata1 = make_kata({ id:id + '1' })
    kata2 = make_kata({ id:id + '2' })
    kata3 = make_kata({ id:id + '3' })
    assert_equal [kata1.id, kata2.id, kata3.id].sort, all_ids.sort
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # katas.completed(id)
  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'B652EC',
  'completed(id=nil) is empty string' do
    assert_equal '', storer.completed(nil)
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'D391CE',
  'completed(id="") is empty string' do
    assert_equal '', storer.completed('')
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '42EA20',
  'completed(id) does not complete when id is less than 6 chars in length',
  'because trying to complete from a short id will waste time going through',
  'lots of candidates (on disk) with the likely outcome of no unique result' do
    id = unique_id[0..4]
    assert_equal 5, id.length
    assert_equal id, storer.completed(id)
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '071A62',
  'completed(id) unchanged when no matches' do
    id = unique_id
    (0..7).each { |size| assert_equal id[0..size], storer.completed(id[0..size]) }
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '23B4F1',
  'completed(id) does not complete when 6+ chars and more than one match' do
    uncompleted_id = 'ABCDE1'
    make_kata({ id:uncompleted_id + '234' + '5' })
    make_kata({ id:uncompleted_id + '234' + '6' })
    assert_equal uncompleted_id, storer.completed(uncompleted_id)
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '0934BF',
  'completed(id) completes when 6+ chars and 1 match' do
    completed_id = 'A1B2C3D4E5'
    make_kata({ id:completed_id })
    uncompleted_id = completed_id.downcase[0..5]
    assert_equal completed_id, storer.completed(uncompleted_id)
  end

  #- - - - - - - - - - - - - - - -
  # start_avatar
  #- - - - - - - - - - - - - - - -

  test '81C023',
  'unstarted avatar does not exist' do
    kata = make_kata
    refute storer.avatar_exists?(kata.id, 'lion')
    assert_equal [], kata.avatars.started.keys
  end

  test '16F7BB',
  'started avatar exists' do
    kata = make_kata
    assert_equal [], kata.avatars.started.keys
    kata.start_avatar(['lion'])
    assert_equal ['lion'], kata.avatars.started.keys
    assert storer.avatar_exists?(kata.id, 'lion')
  end

  #- - - - - - - - - - - - - - - -
  # avatar_increments
  #- - - - - - - - - - - - - - - -

  test '83EF2E',
  'started avatar has empty increments before any tests run' do
    kata = make_kata
    lion = kata.start_avatar(['lion'])
    incs = storer.avatar_increments(kata.id, 'lion')
    assert_equal [], incs
  end

  #- - - - - - - - - - - - - - - -
  # avatar_ran_tests
  #- - - - - - - - - - - - - - - -

  test '89817A',
  'after avatar_tested() one more increment' do
    kata = make_kata
    lion = kata.start_avatar(['lion'])
    maker = DeltaMaker.new(lion)
    now = time_now
    lion.tested(maker.delta, maker.visible_files, now, output='xx', 'amber')
    incs = storer.avatar_increments(kata.id, 'lion')
    assert_equal [{
      'colour' => 'amber',
      'time' => now,
      'number' => 1
    }], incs
  end

  #- - - - - - - - - - - - - - - -
  # paths
  #- - - - - - - - - - - - - - - -

  test 'B55710',
  'katas-path has correct format when set with trailing slash' do
    path = '/tmp/folder'
    set_katas_root(path + '/')
    assert_equal path, storer.path
    assert correct_path_format?(storer.path)
  end

  #- - - - - - - - - - - - - - - -

  test 'B2F787',
  'katas-path has correct format when set without trailing slash' do
    path = '/tmp/folder'
    set_katas_root(path)
    assert_equal path, storer.path
    assert correct_path_format?(storer.path)
  end

  #- - - - - - - - - - - - - - - -

  test '6F3999',
  'kata-path has correct format' do
    kata = make_kata
    assert correct_path_format?(storer.kata_path(kata.id))
  end

  #- - - - - - - - - - - - - - - -

  test '1E4B7A',
  'kata-path is split ala git' do
    kata = make_kata
    split = kata.id[0..1] + '/' + kata.id[2..-1]
    assert storer.kata_path(kata.id).include?(split)
  end

  #- - - - - - - - - - - - - - - -

  test '2ED22E',
  'avatar-path has correct format' do
    kata = make_kata
    avatar = kata.start_avatar(Avatars.names)
    assert correct_path_format?(storer.avatar_path(kata.id, avatar.name))
  end

  #- - - - - - - - - - - - - - - -

  test 'B7E4D5',
  'sandbox-path has correct format' do
    kata = make_kata
    avatar = kata.start_avatar(Avatars.names)
    sandbox_path = storer.sandbox_path(kata.id, avatar.name)
    assert correct_path_format?(sandbox_path)
    assert sandbox_path.include?('sandbox')
  end

  #- - - - - - - - - - - - - - - -
  #- - - - - - - - - - - - - - - -

  test 'CE9083',
  'make_kata saves manifest in kata dir' do
    kata = make_kata
    assert disk[storer.kata_path(kata.id)].exists?('manifest.json')
  end

  #- - - - - - - - - - - - - - - -

  test 'E4EB88',
  'a started avatar is git configured with single quoted user.name/email' do
    kata = make_kata
    salmon = kata.start_avatar(['salmon'])
    assert_log_include?("git config user.name 'salmon_#{kata.id}'")
    assert_log_include?("git config user.email 'salmon@cyber-dojo.org'")
  end

  #- - - - - - - - - - - - - - - -

  test '8EF1A3',
  'sandbox_save(... delta[:new] ...) files are git add.ed' do
    kata = make_kata
    @avatar = kata.start_avatar
    new_filename = 'ab.c'
    maker = DeltaMaker.new(@avatar)
    maker.new_file(new_filename, new_content = 'content for new file')

    git_evidence = "git add '#{new_filename}'"
    refute_log_include?(pathed(git_evidence))

    storer.sandbox_save(kata.id, @avatar.name, maker.delta, maker.visible_files)

    assert_log_include?(pathed(git_evidence))
    assert_file new_filename, new_content
  end

  #- - - - - - - - - - - - - - - -

  test 'A66E09',
  'sandbox_save(... delta[:deleted] ...) files are git rm.ed' do
    kata = make_kata
    @avatar = kata.start_avatar
    maker = DeltaMaker.new(@avatar)
    maker.delete_file('makefile')

    git_evidence = "git rm 'makefile'"
    refute_log_include?(pathed(git_evidence))

    storer.sandbox_save(kata.id, @avatar.name, maker.delta, maker.visible_files)

    assert_log_include?(pathed(git_evidence))
    refute maker.visible_files.keys.include? 'makefile'
  end

  #- - - - - - - - - - - - - - - -

  test '0BF880',
  'sandbox_save(... delta[:changed] ... files are not re git add.ed' do
    kata = make_kata
    avatar = kata.start_avatar
    maker = DeltaMaker.new(avatar)
    maker.change_file('makefile', 'sdsdsd')
    storer.sandbox_save(kata.id, avatar.name, maker.delta, maker.visible_files)
    #??
  end

  #- - - - - - - - - - - - - - - -

  test '2D9F15',
  'sandbox dir is initially created' do
    kata = make_kata
    hippo = kata.start_avatar(['hippo'])
    assert disk[storer.sandbox_path(kata.id, 'hippo')].exists?
  end

  #- - - - - - - - - - - - - - - -
  # tags
  #- - - - - - - - - - - - - - - -

  test 'C42CB0',
  'tag_visible_files' do
    kata = make_kata
    hippo = kata.start_avatar(['hippo'])
    visible_files = storer.tag_visible_files(kata.id, 'hippo', tag=0)
    assert 6, visible_files.length
    assert visible_files.keys.include? 'makefile'
  end

  #- - - - - - - - - - - - - - - -
  #- - - - - - - - - - - - - - - -

  private

  include TimeNow

  def correct_path_format?(path)
    ends_in_slash = path.end_with?('/')
    has_doubled_separator = path.scan('/' * 2).length != 0
    !ends_in_slash && !has_doubled_separator
  end

  def assert_file(filename, expected)
    actual = disk[storer.sandbox_path(@avatar.kata.id, @avatar.name)].read(filename)
    assert_equal expected, actual, 'saved_to_sandbox'
  end

  def assert_log_include?(command)
    assert log.include?(command), lines_of(log)
  end

  def refute_log_include?(command)
    refute log.include?(command), log.to_s
  end

  def lines_of(log)
    log.messages.join("\n")
  end

  def pathed(command)
    sandbox_path = storer.sandbox_path(@avatar.kata.id, @avatar.name)
    "cd #{sandbox_path} && #{command}"
  end
=end

  def make_manifest(kata_id)
    {
      'image_name' => 'cyberdojofoundation/gcc_assert',
      'tab_size' => 4,
      'id' => kata_id
    }
  end

end
