require 'fileutils'

class HostDir

  def initialize(disk, path)
    @disk = disk
    @path = path
    @path += '/' unless @path.end_with?('/')
  end

  attr_reader :path

  def parent
    @disk
  end

  # Use in languages.make_cache
  # Note: language.path will be rooted from / so does not need [parent.path +]
  #
  # def each_rdir(pattern)
  #   # eg pattern = '**/manifest.json'
  #   Dir.glob(path + pattern).each do |entry|
  #     yield File.dirname(entry)
  #   end
  # end

  def each_dir
    return enum_for(:each_dir) unless block_given?
    Dir.entries(path).each do |entry|
      pathed = path + entry
      yield entry if @disk.dir?(pathed) && !dot?(pathed)
    end
  end

  def each_file
    return enum_for(:each_file) unless block_given?
    Dir.entries(path).each do |entry|
      pathed = path + entry
      yield entry unless @disk.dir?(pathed)
    end
  end

  def exists?(filename = nil)
    return File.directory?(path) if filename.nil?
    return File.exists?(path + filename)
  end

  def make
    # -p creates intermediate dirs as required.
    FileUtils.mkdir_p(path)
    # NB: if Dockerfile [USER cyber-dojo]
    #     FAILS: FileUtils.mkdir_p(path)
    #     WORKS: shell.exec("sudo -u cyber-dojo mkdir -p #{path}")
  end

  def write_json_once(filename)
    # The json cache object is not a regular 2nd parameter, it is yielded.
    # This is so it is only created if it is needed.
    File.open(path + filename, File::WRONLY|File::CREAT|File::EXCL, 0644) do |fd|
      fd.write(JSON.unparse(yield)) # yield must return a json object
    end
  rescue Errno::EEXIST
  end

  def write_json(filename, object)
    fail RuntimeError.new("#{filename} doesn't end in .json") unless filename.end_with? '.json'
    write(filename, JSON.unparse(object))
  end

  def write(filename, s)
    fail RuntimeError.new('not a string') unless s.is_a? String
    pathed_filename = path + filename
    File.open(pathed_filename, 'w') { |fd| fd.write(s) }
    File.chmod(0755, pathed_filename) if pathed_filename.end_with?('.sh')
  end

  def read_json(filename)
    fail RuntimeError.new("#{filename} doesn't end in .json") unless filename.end_with? '.json'
    JSON.parse(read(filename))
  end

  def read(filename)
    cleaned(IO.read(path + filename))
  end

  private

  include ExternalParentChainer
  include StringCleaner

  def dot?(name)
    name.end_with?('/.') || name.end_with?('/..')
  end

end
