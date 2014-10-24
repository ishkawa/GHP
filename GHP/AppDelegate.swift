import Cocoa

@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate, GitHubDelegate {
    @IBOutlet var menu: NSMenu!
    var statusItem: NSStatusItem!
    var settingsWindowController: SettingsWindowController?

    var lastDate: NSDate
    let timer: NSTimer

    override init() {
        lastDate = NSDate.distantPast() as NSDate
        timer = NSTimer.scheduledTimerWithTimeInterval(60.0,
            target: GitHub.instance,
            selector: "fetchNotifications",
            userInfo: nil,
            repeats: true)
    }

    // MARK: NSApplicationDelegate
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(35.0)
        statusItem.title = "GHP"
        statusItem.target = self
        statusItem.action = "showMenu"
        statusItem.enabled = true

        GitHub.instance.delegate = self
        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
    }

    // MARK: NSUserNotificationCenterDelegate
    func userNotificationCenter(center: NSUserNotificationCenter, didActivateNotification userNotification: NSUserNotification) {
        if let path = userNotification.userInfo?["path"] as? String {
            GitHub.instance.fetchHTMLURLFromAPIPath(path) { URL in
                let workspace = NSWorkspace.sharedWorkspace()
                workspace.openURL(URL)
            }
        }
    }

    func showMenu() {
        statusItem.popUpStatusItemMenu(menu)
    }

    @IBAction func showSettingsWindow(sender: NSMenuItem) {
        settingsWindowController = SettingsWindowController(windowNibName: "SettingsWindowController")
        settingsWindowController?.showWindow(sender)
        NSApp.activateIgnoringOtherApps(true)
    }

    @IBAction func quit(sender: NSMenuItem) {
    }

    // MARK: GitHubDelegate
    func github(github: GitHub, didReceiveNotification notification: Notification) {
        dispatch_async(dispatch_get_main_queue(), {
            if notification.date.compare(self.lastDate) == .OrderedDescending {
                self.statusItem.title = "GHP"
                self.lastDate = notification.date

                let userNotification = NSUserNotification()
                userNotification.title = "\(notification.type) on \(notification.repository)"
                userNotification.subtitle = notification.title
                userNotification.actionButtonTitle = "Open"
                userNotification.userInfo = ["path": notification.APIPath]

                let center = NSUserNotificationCenter.defaultUserNotificationCenter()
                center.deliverNotification(userNotification)
            }
        })
    }

    func github(github: GitHub, didReceiveError error: NSError) {
        dispatch_async(dispatch_get_main_queue(), {
            self.statusItem.title = "✗"
            println("error: \(error.localizedDescription)")
        })
    }
}

