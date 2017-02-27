
class DownloaderController < ApplicationController

  def download
    send_file zipper.zip(id)
  end

  def download_tag
    send_file zipper.zip_tag(id, avatar_name, tag)
  end

end
