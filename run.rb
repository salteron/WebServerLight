#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

# Script to run WebServerLight

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

require_relative 'app/web_server_light.rb'

WebServerLight.run
