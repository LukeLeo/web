
# this list has order dependencies

%w{
  unslashed
  env_var
  name_of_caller
  externals
  nearest_ancestors

  time_now
  unique_id
  string_cleaner

  disk_host
  dir_host
  shell_host
  log_memory
  log_stdout
}.each { |sourcefile| require_relative './' + sourcefile }
