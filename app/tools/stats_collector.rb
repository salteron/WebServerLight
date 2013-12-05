# -*- encoding : utf-8 -*-

require 'localmemcache'

module WebServerLight
  module Tools
    class StatsCollector
      STATS_FILE_PATH = './viewcounters.lmc'

      class << self
        attr_accessor :stats
      end

      @stats = LocalMemCache.new filename: STATS_FILE_PATH

      def initialize
        @mutex = Mutex.new
      end

      def collect(file_path)
        Thread.new do
          @mutex.synchronize do
            StatsCollector.stats[file_path] ||= 0
            StatsCollector.stats[file_path] =
              StatsCollector.stats[file_path].to_i + 1
          end
        end
      rescue LocalMemCacheError => e
        puts e.message.red
      end
    end
  end
end
