#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-
cur_dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift cur_dir

require 'web_server_light.rb'

params = {}
params[:base_path] = ARGV[0] if ARGV[0]
params[:timeout]   = ARGV[1] if ARGV[1]

WebServerLight.new(params).run
