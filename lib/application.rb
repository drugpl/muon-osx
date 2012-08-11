require 'rubygems' # disable this for a deployed application
require 'hotcocoa'

$:.unshift File.dirname(__FILE__)
$:.unshift File.expand_path('../../ext', __FILE__)
$:.unshift ENV["MUON_LIB_DIR"] # remove this once muon gem is released

require 'muon/osx/app'

Muon::OSX::App.new.start
