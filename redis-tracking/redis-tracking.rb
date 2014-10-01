#!/usr/bin/env ruby
require_relative '../lib/hls-log-monitor'

require 'sinatra/base'
require 'digest/md5'
require 'redis'
require 'json'

ACCESS_LOG, STREAM_PATH = '/var/log/nginx/access_log', '/hls/livestream'
REDIS_PREFIX = 'hls.'
REDIS_EXPIRE = 5

$redis = Redis.new()

module RedisTracking
  def self.start_monitoring()
    HLSLogMonitor( :access_log => ACCESS_LOG,
                   :stream_path => STREAM_PATH  ) do |entry|
      whitespace_splits, quote_splits = entry.split(' '), entry.chomp.split('"')
      ip_addr, user_agent = whitespace_splits.first, quote_splits.last
      client_id = Digest::MD5.hexdigest( [ip_addr, user_agent].join() )[0,10]
      p [client_id, ip_addr, user_agent]
      self.set_key( client_id, { 'ip_addr' => ip_addr, 'user_agent' => user_agent } )
    end
  end

  def self.set_key(k, v)
    key = REDIS_PREFIX+k
    $redis.set(key, v.to_json)
    $redis.expire(key, REDIS_EXPIRE)
  end

  def fetch_clients()
    clients = {}
    $redis.keys(REDIS_PREFIX+"*").each do |k|
      raw_json = $redis.get(k)
      k.gsub!(REDIS_PREFIX, '')
      clients.store(k, JSON.load(raw_json))
    end
    clients
  end

  class Web < Sinatra::Base
    get '/' do
      erb :index
    end

    get '/fetch_clients' do
      RedisTracking::fetch_clients().to_json
    end
  end

end

include RedisTracking
