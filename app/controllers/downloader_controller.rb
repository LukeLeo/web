
class DownloaderController < ApplicationController

  def download
    # an id such as 01FE818E68 corresponds to the folder katas/01/FE818E86
    fail "sorry can't do that" if katas[id].nil?

    # Create files off /tmp in new format
    download_path = '/tmp/cyber-dojo/downloads'
    kata_path = "#{download_path}/#{outer(id)}/#{inner(id)}"
    kata_dir = disk[kata_path]
    kata_dir.make
    kata_dir.write_json('manifest.json', storer.kata_manifest(id))
    katas[id].avatars.each do |avatar|
      avatar_path = "#{kata_path}/#{avatar.name}"
      avatar_dir = disk[avatar_path]
      avatar_dir.make
      rags = storer.avatar_increments(id, avatar.name)
      avatar_dir.write_json('increments.json', rags)
      (0..rags.size).each do |tag|
        tag_path = "#{avatar_path}/#{tag}"
        tag_dir = disk[tag_path]
        tag_dir.make
        visible_files = storer.tag_visible_files(id, avatar.name, tag)
        tag_dir.write_json('manifest.json', visible_files)
      end
    end
    # and tar that
    cd_cmd = "cd #{download_path}"
    tar_filename = "#{download_path}/#{id}.tgz"
    tar_cmd = "tar -zcf #{tar_filename} #{outer(id)}/#{inner(id)}"
    system(cd_cmd + ' && ' + tar_cmd)
    send_file tar_filename
  end

  private

  include IdSplitter

end
