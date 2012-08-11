framework 'CoreServices'

module Muon
  module OSX
    class ProjectMonitor
      def initialize(project)
        @project = project
      end

      def startMonitoring(&block)
        callback = Proc.new do |stream, client_callback_info, number_of_events, paths_pointer, event_flags, event_ids|
          block.call
        end

        paths = [@project.working_dir]
        stream = FSEventStreamCreate(KCFAllocatorDefault, callback, nil, paths, KFSEventStreamEventIdSinceNow, 0.0, 0)
        FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), KCFRunLoopDefaultMode)
        FSEventStreamStart(stream)
      end
    end
  end
end
