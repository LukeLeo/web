
module DifferWorker

  module_function

  def was_tag
    tag(:was_tag)
  end

  def now_tag
    tag(:now_tag)
  end

  def tag(n)
    raw = params[n].to_i
    raw != -1 ? raw : @lights.length
  end

  def current_filename
    params[:current_filename]
  end

  def active_avatar_names
    @active_avatar_names ||= avatars.active.map(&:name).sort
  end

  def prune(array)
    array.map { |hash| { :id => hash[:id], :section_count => hash[:section_count] } }
  end

  include RingPicker
  include GitDiff
  include ReviewFilePicker

end
