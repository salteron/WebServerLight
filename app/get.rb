require 'rest_client'

N = ARGV[0] || 1
RESOURCE = '/img.jpg'

Thread.abort_on_exception = true
threads = []

N.times do
  threads << Thread.new do
    RestClient.get 'localhost:3000' + RESOURCE
  end
end

threads.each(&:join)