require 'muon/app'
require 'IdleTime'

module Muon
  module OSX
    class App
      IDLE_CHECK_INTERVAL = 5

      include HotCocoa

      def start
        app = NSApplication.sharedApplication
        app.delegate = self

        @projects = Muon::App.new("").global_projects

        initMenu
        initStatusItem
        initSleepNotifications
        initIdleNotifications

        app.run
      end

      def initMenu
        @menu = NSMenu.new
        @menu.initWithTitle 'FooApp'

        @projects.each_with_index do |project, i|
          item = NSMenuItem.alloc.initWithTitle project.name, action: "projectClicked:", keyEquivalent: ""
          item.tag = i
          @menu.addItem item
        end

        @menu.addItem NSMenuItem.separatorItem
        @menu.addItem NSMenuItem.alloc.initWithTitle "Quit", action: "quit:", keyEquivalent: ""
      end

      def initStatusItem
        statusItem = NSStatusBar.systemStatusBar.statusItemWithLength(NSVariableStatusItemLength)
        statusItem.setMenu @menu
        statusItem.setTitle "Muon"
        statusItem.setHighlightMode true
        # img = NSImage.new.initWithContentsOfFile ''
        # statusItem.setImage(img)
      end

      def sayHello(sender)
        alert = NSAlert.new
        alert.messageText = 'This is MacRuby Status Bar Application'
        alert.informativeText = 'Cool, huh?'
        alert.alertStyle = NSInformationalAlertStyle
        alert.addButtonWithTitle("Yeah!")
        response = alert.runModal
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

      def projectClicked(sender)
        p @projects[sender.tag].path
      end

      def quit(sender)
        app = NSApplication.sharedApplication
        app.terminate(self)
      end
    end
  end
end
