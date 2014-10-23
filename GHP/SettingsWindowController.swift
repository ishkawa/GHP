import Cocoa

class SettingsWindowController: NSWindowController {
    @IBOutlet weak var baseURLField: NSTextField!
    @IBOutlet weak var accessTokenField: NSTextField!

    override func windowDidLoad() {
        super.windowDidLoad()

        if let baseURL = GitHub.instance.baseURL.absoluteString {
            baseURLField.stringValue = baseURL
        }

        if let accessToken = GitHub.instance.accessToken {
            accessTokenField.stringValue = accessToken
        }
    }

    @IBAction func save(sender: NSButton) {
        let github = GitHub.instance

        if let baseURL = NSURL(string: baseURLField.stringValue) {
            github.baseURL = baseURL
        }

        github.accessToken = accessTokenField.stringValue
        github.saveCurrentConfiguration()
    }
}
