#!/usr/bin/env ruby
require_relative 'lib/hls-log-monitor'
require 'digest/md5'

HLSLogMonitor( :access_log => '/var/log/nginx/access_log',
               :stream_path => '/hls/livestream'  ) do |entry|

  whitespace_splits, quote_splits = entry.split(' '), entry.chomp.split('"')
  ip_addr, user_agent = whitespace_splits.first, quote_splits.last
  client_id = Digest::MD5.hexdigest( [ip_addr, user_agent].join() )
  p [client_id, ip_addr, user_agent]

end
