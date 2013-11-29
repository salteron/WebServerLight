#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-
$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

require 'web_server_light.rb'

WebServerLight.new.run
