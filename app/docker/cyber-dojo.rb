#!/usr/bin/env ruby

require 'json'

def me; 'cyber-dojo'; end

def my_dir; File.expand_path(File.dirname(__FILE__)); end

def docker_hub_username; 'cyberdojofoundation'; end

def docker_version; ENV['DOCKER_VERSION']; end

def home; '/usr/src/cyber-dojo'; end  # home folder *inside* the server image

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def help
  [
    '',
    "Use: #{me} COMMAND",
    "     #{me} [help]",
    '',
    '    clean                          Removes dead images',
    '    down                           Brings down the server',
    '    pull IMAGE                     Pulls the named docker IMAGE',
    '    remove IMAGE                   Removes a pulled language IMAGE',
    '    sh [COMMAND]                   Shells into the server (and run COMMAND if provided)',
    '    up [NAME...]                   Brings up the server using the default/named volumes',
    '    upgrade                        Pulls the latest server and language images',
    '    volume                         Manage cyber-dojo volumes',
    '',
  ].join("\n") + "\n"
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def run(command)
  puts command
  `#{command}`
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def clean
  run "docker images -q -f='dangling=true' | xargs docker rmi --force"
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def up
  return unless languages == []
  puts 'No language images pulled'
  puts 'Pulling a small starting collection of common language images'
  starting = %w( gcc_assert gpp_assert csharp_nunit java_junit python_pytest ruby_mini_test )
  starting.each { |image| pull(image) }
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# volume

def space
  ' '
end

def tab
  space * 4
end

def minitab
  space * 2
end

def volume
  lines = [
    '',
    'Use: cyber-dojo volume [COMMAND]',
    '',
    'Commands:',
    minitab + 'create              Creates a new volume to use with the [up] command',
    minitab + 'rm                  Removes one or more volumes',
    minitab + 'ls                  Lists the names of all volumes',
    minitab + 'inspect             Displays details of one or more volume',
    minitab + 'pull                Pulls docker images named in one or more volumes',
    '',
    "Run 'cyber-dojo volume COMMAND --help' for more information on a command",
  ]
  if [nil,'help','--help'].include? ARGV[1]
    lines.each { |line| puts line }
  else
    case ARGV[1]
    when 'create'  then volume_create
    when 'rm'      then volume_rm
    when 'ls'      then volume_ls
    when 'inspect' then volume_inspect
    when 'pull'    then volume_pull
    #...otherwise...
    end
  end
end

# - - - - - - - - - - - - - - -

def volume_create
  lines = [
    '',
    "Use: #{me} volume create --name=NAME --git=URL",
    '',
    '     Creates a volume named NAME as git clone of URL',
    '     and pulls all its docker images marked auto_pull:true'
  ]
  if [nil,'help','--help'].include? ARGV[2]
    lines.each { |line| puts line }
  else
    p "do volume create..."
  end
end

# - - - - - - - - - - - - - - -

def volume_rm
  lines = [
    '',
    "Use: #{me} volume rm VOL [VOL...]",
    '',
    '     Removes one or more volumes created with the command',
    "     #{me} volume create"
  ]
  if [nil,'help','--help'].include? ARGV[2]
    lines.each { |line| puts line }
  else
    p "do volume rm..."
  end
end

# - - - - - - - - - - - - - - -

def volume_ls
  p 'volume ls'
  #minitab + 'ls                  Lists the names of all volumes',
end

# - - - - - - - - - - - - - - -

def volume_inspect
  p 'volume inspect'
  # was catalog
  #minitab + 'inspect NAME        Shows details of the named volume', #(WAS catalog)
end

# - - - - - - - - - - - - - - -

def volume_pull
  p 'volume pull'
  #minitab + 'pull NAME           ....',
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# catalog

$longest_test = ''
$longest_language = ''

def docker_images_pulled
  `docker images`.split("\n").map{ |line| line.split[0] }
  # cyberdojofoundation/visual-basic_nunit   latest  eb5f54114fe6 4 months ago 497.4 MB
  # cyberdojofoundation/ruby_mini_test       latest  c7d7733d5f54 4 months ago 793.4 MB
  # cyberdojofoundation/ruby_rspec           latest  ce9425d1690d 4 months ago 411.2 MB
  # -->
  # cyberdojofoundation/visual-basic_nunit
  # cyberdojofoundation/ruby_mini_test
  # cyberdojofoundation/ruby_rspec
end

def docker_images_from_manifests(root)
  pulled = docker_images_pulled
  hash = {}
  Dir.glob("#{root}/**/manifest.json") do |file|
    manifest = JSON.parse(IO.read(file))
    language, test = manifest['display_name'].split(',').map { |s| s.strip }
    $longest_language = max_size($longest_language, language)
    $longest_test = max_size($longest_test, test)
    image = manifest['image_name']
    hash[language] ||= {}
    hash[language][test] = {
      'image' => image,
      'pulled' => pulled.include?(image) ? 'yes' : 'no'
    }
  end
  hash
end

def max_size(lhs, rhs)
  lhs.size > rhs.size ? lhs : rhs
end

def spacer(longest, name)
  ' ' * (longest.size - name.size)
end

def catalog_line(language, test, pulled, image)
  language_spacer = spacer($longest_language, language)
  test_spacer = spacer($longest_test, test)
  pulled_spacer = spacer(3, pulled)
  gap = ' ' * 3
  line = ''
  line += language + language_spacer + gap
  line += test + test_spacer + gap
  line += pulled + pulled_spacer + gap
  line += image
end

def catalog
  root = File.expand_path('../data/languages', File.dirname(__FILE__))
  all = docker_images_from_manifests(root)
  lines = []
  lines << catalog_line('LANGUAGE', 'TESTS', 'PULLED', 'IMAGE')
  all.sort.map do |language,tests|
    tests.sort.map do |test, hash|
      pulled = hash['pulled']
      image = hash['image']
      lines << catalog_line(language, test, pulled, image)
    end
  end
  lines.join("\n")
  # LANGUAGE          TESTS                PULLED  IMAGE
  # Asm               assert               yes     cyberdojofoundation/nasm_assert
  # BCPL              all_tests_passed     no      cyberdojofoundation/bcpl-all_tests_passed
  # Bash              shunit2              no      cyberdojofoundation/bash_shunit2
  # C (clang)         assert               yes     cyberdojofoundation/clang_assert
  # C (gcc)           CppUTest             yes     cyberdojofoundation/gcc_cpputest
  # ...
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def all_languages
  catalog.split("\n").drop(1).map{ |line| line.split[-1] }
  # [ bcpl-all_tests_passed, bash_shunit2, clang_assert, gcc_cpputest, ...]
end

def in_catalog?(image)
  all_languages.include?(image)
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def languages
  lines = catalog.split("\n").drop(1)
  lines.select { |line| line.split[-2] == 'yes' }.map { |line| line.split[-1] }
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def docker_pull(image, tag)
  run "docker pull #{docker_hub_username}/#{image}:#{tag}"
end

def upgrade
  languages.each { |image| docker_pull(image, 'latest') }
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def bad_image(image)
  if image.nil?
    puts 'missing IMAGE'
  else
    puts "unknown IMAGE #{image}"
  end
  puts "Try '#{me} help'"
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def pull(image)
  if image == 'all'
    all_languages.each do |language|
      docker_pull(language, 'latest')
    end
  elsif in_catalog?(image)
    docker_pull(image, 'latest')
  else
    bad_image(image)
  end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def remove(image)
  if languages.include?(image)
    run "docker rmi #{docker_hub_username}/#{image}"
  elsif all_languages.include?(image)
    puts "IMAGE #{image} is not installed"
    puts "Try '#{me} help'"
  else
    bad_image(image)
  end
end

#= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

if ARGV.length == 0
  puts help
  exit
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

options = {}
arg = ARGV[0]
container_commands = ['down', 'sh', 'up']
image_commands = ['clean', 'catalog', 'pull', 'remove', 'upgrade']
all_commands = ['--help','help'] + ['volume'] + container_commands + image_commands
if all_commands.include? arg
  options[arg] = true
else
  puts "#{me}: '#{arg}' is not a command."
  puts "See '#{me} --help'."
  exit
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

puts help       if options['--help'] || options['help']
volume          if options['volume']
up              if options['up']

puts catalog    if options['catalog']
clean           if options['clean']
pull(ARGV[1])   if options['pull']
remove(ARGV[1]) if options['remove']
upgrade         if options['upgrade']
