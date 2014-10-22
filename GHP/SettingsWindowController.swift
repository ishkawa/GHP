import Cocoa

class SettingsWindowController: NSWindowController {
    @IBOutlet weak var baseURLField: NSTextField!
    @IBOutlet weak var accessTokenField: NSTextField!

    override func windowDidLoad() {
        super.windowDidLoad()
    }
}
