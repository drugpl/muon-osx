require 'muon/app'
require 'muon/osx/project_monitor'
require 'IdleTime'

module Muon
  module OSX
    class App
      IDLE_CHECK_INTERVAL = 5

      include HotCocoa

      def start
        app = NSApplication.sharedApplication
        app.delegate = self

        initProjects
        initMenu
        initStatusItem
        initSleepNotifications
        initIdleNotifications

        app.run
      end

      def initProjects
        @projects = Muon::App.new("").global_projects
        @projects.each_with_index do |project, i|
          ProjectMonitor.new(project).startMonitoring { projectMonitorUpdated(project, i) }
        end
      end

      def initMenu
        @menu = NSMenu.new
        @menu.initWithTitle "Muon"

        @projects.each_with_index do |project, i|
          item = NSMenuItem.alloc.initWithTitle titleForProject(project), action: "projectClicked:", keyEquivalent: ""
          item.tag = i
          @menu.addItem item
        end

        @menu.addItem NSMenuItem.separatorItem
        @menu.addItem NSMenuItem.alloc.initWithTitle "Quit", action: "quit:", keyEquivalent: ""
      end

      def initStatusItem
        @statusItem = NSStatusBar.systemStatusBar.statusItemWithLength(NSVariableStatusItemLength)
        @statusItem.setMenu @menu
        @statusItem.setHighlightMode true
        setMenuIcon
      end

      def initSleepNotifications
        notificationCenter = NSWorkspace.sharedWorkspace.notificationCenter
        notificationCenter.addObserver self, selector: :receiveSleepNote, name: NSWorkspaceWillSleepNotification, object: nil
        notificationCenter.addObserver self, selector: :receiveWakeNote, name: NSWorkspaceDidWakeNotification, object: nil
      end

      def initIdleNotifications
        Thread.new do
          it = IdleTime.new
          loop do
            self.performSelectorOnMainThread 'receiveIdleNote:', withObject: it.secondsIdle, waitUntilDone: false
            sleep IDLE_CHECK_INTERVAL
          end
        end
      end

      def receiveSleepNote
        puts "sleepNote"
      end

      def receiveWakeNote
        puts "wakeNote"
      end

      def receiveIdleNote(seconds)
        puts "idle #{seconds}"
      end

      def projectMonitorUpdated(project, i)
        @menu.itemWithTag(i).setTitle titleForProject(project)
        setMenuIcon
      end

      def projectClicked(sender)
        p @projects[sender.tag].path
      end

      def quit(sender)
        app = NSApplication.sharedApplication
        app.terminate(self)
      end

      protected

      def setMenuIcon
        @imgStopped ||= NSImage.alloc.initWithContentsOfFile(
          NSBundle.mainBundle.pathForResource("icon-stopped", ofType: "png"))
        @imgRunning ||= NSImage.alloc.initWithContentsOfFile(
          NSBundle.mainBundle.pathForResource("icon-running", ofType: "png"))

        if @projects.any?(&:tracking?)
          @statusItem.setImage(@imgRunning)
        else
          @statusItem.setImage(@imgStopped)
        end
      end

      def titleForProject(project)
        if project.tracking?
          "#{project.name} (running)"
        else
          project.name
        end
      end
    end
  end
end
