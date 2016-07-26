
module TestDomainHelpers # mix-in

  module_function

  def dojo; @dojo ||= Dojo.new; end

  def languages; dojo.languages; end
  def exercises; dojo.exercises; end

  def custom; dojo.custom; end

  def runner;    dojo.runner;    end
  def katas;     dojo.katas;     end
  def shell;     dojo.shell;     end
  def disk;      dojo.disk;      end
  def log;       dojo.log;       end
  def git;       dojo.git;       end

  def make_kata(hash = {})
    hash[:id] ||= unique_id
    hash[:now] ||= time_now
    hash[:language] ||= default_language_name
    language = languages[hash[:language]]
    manifest = katas.create_kata_manifest(language, hash[:id], hash[:now])
    hash[:exercise] ||= default_exercise_name
    exercise = exercises[hash[:exercise]]
    manifest[:exercise] = exercise.name
    manifest[:visible_files]['instructions'] = exercise.text

    katas.create_kata_from_kata_manifest(manifest)
  end

  def unique_id
    hex_chars = "0123456789ABCDEF".split(//)
    Array.new(10) { hex_chars.sample }.shuffle.join
  end

  def time_now(now = Time.now)
    [now.year, now.month, now.day, now.hour, now.min, now.sec]
  end

  def default_language_name
    # The first to be Alpine'd and so the smallest
    'C (clang)-assert'
  end

  def default_exercise_name
    'Fizz_Buzz'
  end

end
