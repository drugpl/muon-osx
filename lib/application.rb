require 'rubygems' # disable this for a deployed application
require 'hotcocoa'
require File.dirname(__FILE__) + '/../ext/IdleTime'

class Muon
  IDLE_CHECK_INTERVAL = 5

  include HotCocoa

  def start
    app = NSApplication.sharedApplication
    app.delegate = self
    initMenu
    initStatusItem
    initSleepNotifications
    initIdleNotifications
    app.run
  end

  def initMenu
    @menu = NSMenu.new
    @menu.initWithTitle 'FooApp'
    mi = NSMenuItem.new
    mi.title = 'Hellow from MacRuby!'
    mi.action = 'sayHello:'
    mi.target = self
    @menu.addItem mi

    # mi = NSMenuItem.new
    # mi.title = 'Quit'
    # mi.action = 'quit:'
    # mi.target = self
    # menu.addItem mi
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
end

Muon.new.start
