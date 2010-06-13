
class KataController < ApplicationController

  def index
    @dojo = Dojo.new(params[:dojo_name])
    @avatar_name = params[:avatar_name]
  end

  def view
    @dojo = Dojo.new(params[:dojo_name])
    @kata = @dojo.new_kata(params[:kata_name])
    @avatar = @kata.new_avatar(params[:avatar_name])
    @manifest = {}
    @increments = limited(@avatar.read_most_recent(@manifest))
    @current_file = @manifest[:current_filename] || 'kata.sh'
    @run_tests_output = @manifest[:run_tests_output] || ''
  end

  def run_tests
    dojo = Dojo.new(params[:dojo_name])
    kata = dojo.new_kata(params[:kata_name])
    avatar = kata.new_avatar(params[:avatar_name])
    @run_tests_output = avatar.run_tests(load_files_from_page)
    @increments = limited(avatar.increments)
    respond_to do |format|
      format.js if request.xhr?
    end
  end
  
private

  def dequote(filename)
    # <input name="file_content['wibble.h']" ...>
    # means filename has a leading and trailing single quote
    # which needs to be stripped off
    return filename[1..-2] 
  end

  def load_files_from_page
    manifest = { :visible_files => {} }

    (params[:file_content] || {}).each do |filename,content|
      filename = dequote(filename)
      manifest[:visible_files][filename] = {}
      manifest[:visible_files][filename][:content] = content.split("\r\n").join("\n")  
    end

    (params[:file_caret_pos] || {}).each do |filename,caret_pos|
      filename = dequote(filename)
      manifest[:visible_files][filename][:caret_pos] = caret_pos
    end

    manifest[:current_filename] = params['filename']

    manifest
  end

end

def limited(increments)
  max_increments_displayed = 7
  len = [increments.length, max_increments_displayed].min
  increments[-len,len].reverse
end




