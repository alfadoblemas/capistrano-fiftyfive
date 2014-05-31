require 'colorize'

if Capistrano::VERSION == "3.2.0"
  $stderr.puts\
    "WARNING: Capistrano 3.2.0 has a critical bug that prevents "\
    "capistrano-fiftyfive from working as intended:\n"\
    "https://github.com/capistrano/capistrano/issues/1004".colorize(:red)
end
