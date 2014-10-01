require 'file-tail'

def HLSLogMonitor(args)
  File.open(args[:access_log]) do |log|
    log.extend(File::Tail)
    log.interval = 10
    log.backward(10)
    log.tail do |ln|
      if ln.include?(args[:stream_path])
        yield ln
      end
    end
  end
end
