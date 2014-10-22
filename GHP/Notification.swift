import Foundation

class Notification {
    let id: String
    let repository: String
    let type: String
    let title: String
    let date: NSDate
    let APIPath: String

    class func foo() -> NSDateFormatter {
        return NSDateFormatter()
    }

    class var dateFormatter: NSDateFormatter {
        struct Singleton {
            static let dateFormatter = NSDateFormatter()
        }

        let formatter = Singleton.dateFormatter
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = NSLocale.currentLocale()
        formatter.timeZone = NSTimeZone.localTimeZone()
        formatter.calendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)

        return formatter
    }

    init?(dictionary: NSDictionary) {
        let id = dictionary["id"] as? String
        let repository = dictionary["repository"]?["full_name"] as? String
        let type = dictionary["subject"]?["type"] as? String
        let title = dictionary["subject"]?["title"] as? String

        var APIPath: String?
        if let string = dictionary["subject"]?["latest_comment_url"] as? String {
            if let URL = NSURL(string: string) {
                APIPath = URL.path
            }
        }

        var date: NSDate?
        if let string = dictionary["updated_at"] as? String {
            date = Notification.dateFormatter.dateFromString(string)
        }

        if id == nil || repository == nil || type == nil || title == nil || date == nil || APIPath == nil {
            // initializing stored properties is required for failing in Swift 1.1
            self.id = ""; self.repository = ""; self.type = ""; self.title = ""; self.APIPath = ""; self.date = NSDate()
            return nil
        }

        self.id = id!
        self.repository = repository!
        self.type = type!
        self.title = title!
        self.date = date!
        self.APIPath = APIPath!
    }
}
