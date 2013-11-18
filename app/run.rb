#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-
$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

require 'web_server_light.rb'

params = {}
params[:base_path] = ARGV[0] if ARGV[0]
params[:timeout]   = ARGV[1] if ARGV[1]
params[:port]      = ARGV[2] if ARGV[2]

WebServerLight.new(params).run
