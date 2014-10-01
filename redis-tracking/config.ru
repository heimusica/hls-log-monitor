require './redis-tracking'
fork do
  RedisTracking::start_monitoring()
end
run Web
