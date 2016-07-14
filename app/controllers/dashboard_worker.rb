
module DashboardWorker # mixin

  module_function

  def animals_progress
    animals = {}
    avatars.active.each do |avatar|
      animals[avatar.name] = {
          colour: avatar.lights[-1].colour,
        progress: most_recent_progress(avatar)
      }
    end
    animals
  end

  def gather
    @kata = kata
    @minute_columns = bool('minute_columns')
    @auto_refresh = bool('auto_refresh')
    all_lights = Hash[
      @kata.avatars.active.each.collect{|avatar| [avatar.name, avatar.lights]}
    ]
    max_seconds_uncollapsed = seconds_per_column * 5
    gapper = TdGapper.new(@kata.created, seconds_per_column, max_seconds_uncollapsed)
    @gapped = gapper.fully_gapped(all_lights, time_now)
    @progress = @kata.progress_regexs != [ ]
    @avatar_names = @kata.avatars.active.map { |avatar| avatar.name }.sort
  end

  def bool(attribute)
    tf = params[attribute]
    tf == 'false' ? tf : 'true'
  end

  def seconds_per_column
    flag = params['minute_columns']
    # default is that time-gaps are on
    return 60 if flag.nil? || flag == 'true'
    return 60*60*24*365*1000
  end

  def most_recent_progress(avatar)
    regexs = avatar.kata.progress_regexs
    non_amber = avatar.lights.reverse.find{ |light|
      [:red,:green].include?(light.colour)
    }
    output = (non_amber != nil) ? non_amber.output : ''
    matches = regexs.map { |regex| Regexp.new(regex).match(output) }
    return {
        text: matches.join,
      colour: (matches[0] != nil ? 'red' : 'green')
    }
  end

  include TimeNow

end
