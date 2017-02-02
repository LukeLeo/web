require_relative 'http_service'
require 'json'
require 'net/http'

class RunnerService

  def initialize(_parent)
  end

  def new_kata(image_name, kata_id)
    post(__method__, image_name, kata_id)
  end

  def old_kata(image_name, kata_id)
    post(__method__, image_name, kata_id)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def new_avatar(image_name, kata_id, avatar_name, starting_files)
    post(__method__, image_name, kata_id, avatar_name, starting_files)
  end

  def old_avatar(image_name, kata_id, avatar_name)
    post(__method__, image_name, kata_id, avatar_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def run(image_name, kata_id, avatar_name, deleted_filenames, changed_files, max_seconds)
    args = [image_name, kata_id, avatar_name, deleted_filenames, changed_files, max_seconds]
    sss = post(__method__, *args)
    [sss['stdout'], sss['stderr'], sss['status']]
  end

  private

  include HttpService
  def hostname; 'runner'; end
  def port; 4557; end

end
