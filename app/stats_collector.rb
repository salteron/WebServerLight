# -*- encoding : utf-8 -*-

class StatsCollector
  class << self
    attr_accessor :stats
  end

  @stats = {}

  def initialize
    @mutex = Mutex.new
  end

  def collect(file_path)
    Thread.new do
      @mutex.synchronize do
        StatsCollector.stats[file_path] ||= 0
        StatsCollector.stats[file_path] += 1
      end
    end
  end
end
