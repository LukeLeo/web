
%w(
  name_of_caller
  manifest_property

  dojo
  custom_exercises
  language
  languages_rename
  languages
  exercise
  exercises
  kata
  avatar
  avatars
  sandbox
  tag
).each { |sourcefile| require_relative './' + sourcefile }
