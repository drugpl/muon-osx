APPSPEC = 'Muon.appspec'

require 'rubygems'
require 'hotcocoa/rake_tasks'

task :default => :run

task :build_ext do
  system("cd ext ; macruby extconf.rb ; make") unless File.exists?("ext/IdleTime.bundle")
end

task :build => [:build_ext]
