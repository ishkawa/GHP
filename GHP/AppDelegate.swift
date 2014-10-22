import Cocoa

@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate, GitHubDelegate {
    var lastDate: NSDate
    let client: GitHub
    let timer: NSTimer

    override init() {
        let accessToken = ""
        let baseURL = NSURL(string: "https://api.github.com")
        assert(baseURL != nil, "base URL should not be nil.")

        lastDate = NSDate.distantPast() as NSDate
        client = GitHub(baseURL: baseURL!, accessToken: accessToken)
        timer = NSTimer.scheduledTimerWithTimeInterval(5.0,
            target: client,
            selector: "fetchNotifications",
            userInfo: nil,
            repeats: true)
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        client.delegate = self
        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
    }


    // MARK: NSUserNotificationCenterDelegate
    func userNotificationCenter(center: NSUserNotificationCenter, didActivateNotification userNotification: NSUserNotification) {
        if let path = userNotification.userInfo?["path"] as? String {
            client.fetchHTMLURLFromAPIPath(path) { URL in
                let workspace = NSWorkspace.sharedWorkspace()
                workspace.openURL(URL)
            }
        }
    }

    // MARK: GitHubDelegate
    func github(github: GitHub, didReceiveNotification notification: Notification) {
        dispatch_async(dispatch_get_main_queue(), {
            if notification.date.compare(self.lastDate) == .OrderedDescending {
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
            let userNotification = NSUserNotification()
            userNotification.title = "GHP failed to access GitHub"
            userNotification.subtitle = error.localizedDescription

            let center = NSUserNotificationCenter.defaultUserNotificationCenter()
            center.deliverNotification(userNotification)
        })
    }
}

