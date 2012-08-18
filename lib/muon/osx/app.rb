require 'muon/app'
require 'muon/format'
require 'muon/osx/project_monitor'
require 'IdleTime'

module Muon
  module OSX
    class App
      IDLE_CHECK_INTERVAL = 5
      IDLE_ALERT_THRESHOLD = 5*60

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
        @sleepedAt = Time.now
      end

      def receiveWakeNote
        if hasActiveProjects?
          displayWakeAlert(Time.now - @sleepedAt)
        end
      end

      def receiveIdleNote(seconds)
        if hasActiveProjects? && seconds > IDLE_ALERT_THRESHOLD && ! @idleAlertDisplayed
          displayIdleAlert(seconds)
        end
      end

      def projectMonitorUpdated(project, i)
        @menu.itemWithTag(i).setTitle titleForProject(project)
        setMenuIcon
      end

      def projectClicked(sender)
        project = @projects[sender.tag]
        if project.tracking?
          project.stop_tracking
        else
          project.start_tracking
        end
      end

      def quit(sender)
        app = NSApplication.sharedApplication
        app.terminate(self)
      end

      private

      def setMenuIcon
        @imgStopped ||= NSImage.alloc.initWithContentsOfFile(
          NSBundle.mainBundle.pathForResource("icon-stopped", ofType: "png"))
        @imgRunning ||= NSImage.alloc.initWithContentsOfFile(
          NSBundle.mainBundle.pathForResource("icon-running", ofType: "png"))

        if hasActiveProjects?
          @statusItem.setImage(@imgRunning)
        else
          @statusItem.setImage(@imgStopped)
        end
      end

      def displayWakeAlert(sleepSeconds)
        alert = NSAlert.new
        alert.setInformativeText "Computer has been sleeping for #{Format.duration sleepSeconds}. Do you want to stop tracking time at the point computer was put to sleep?"
        alert.addButtonWithTitle "Stop tracking time"
        alert.addButtonWithTitle "Continue tracking"
        NSApplication.sharedApplication.activateIgnoringOtherApps(true)
        result = alert.runModal
        if result == NSAlertFirstButtonReturn
          activeProjects.each { |project| project.stop_tracking(@sleepedAt) }
        end
      end

      def displayIdleAlert(idleSeconds)
        @idleAlertDisplayed = true
        alert = NSAlert.new
        alert.setMessageText "Computer has been idle for #{Format.duration idleSeconds}. Do you want to stop tracking at the point you stopped using the computer?"
        alert.addButtonWithTitle "Stop tracking time"
        alert.addButtonWithTitle "Continue tracking"
        NSApplication.sharedApplication.activateIgnoringOtherApps(true)
        result = alert.runModal
        if result == NSAlertFirstButtonReturn
          # TODO fix time passed to stop_tracking!
          activeProjects.each { |project| project.stop_tracking }
        end
        @idleAlertDisplayed = false
      end

      def titleForProject(project)
        if project.tracking?
          "#{project.name} (running)"
        else
          project.name
        end
      end

      def hasActiveProjects?
        @projects.any?(&:tracking?)
      end

      def activeProjects
        @projects.select(&:tracking?)
      end
    end
  end
end
