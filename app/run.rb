#!/usr/bin/env ruby
cur_dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift cur_dir

require 'web_server_light.rb'

base_path = ARGV[0] && File.directory?(ARGV[0]) ? File.expand_path(ARGV[0]) :
                                                  File.expand_path("#{cur_dir}/../public")

WebServerLight.run base_path