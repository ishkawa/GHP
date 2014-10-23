import Foundation

private let NSUserDefaultsBaseURLKey  = "NSUserDefaultsBaseURLKey"
private let UICKeychainAccessTokenKey = "UICKeychainAccessTokenKey"

protocol GitHubDelegate {
    func github(github: GitHub, didReceiveNotification notification: Notification)
    func github(github: GitHub, didReceiveError error: NSError)
}

class GitHub: NSObject {
    class var instance: GitHub {
        struct Singleton {
            static let instance = GitHub()
        }
        return Singleton.instance
    }

    var baseURL: NSURL
    var accessToken: String?
    var delegate: GitHubDelegate?

    override init() {
        let userDefaults = NSUserDefaults.standardUserDefaults()

        var savedURL: NSURL?
        if let savedURLString = userDefaults.objectForKey(NSUserDefaultsBaseURLKey) as? String {
            savedURL = NSURL(string: savedURLString ?? "https://api.github.com")
        }

        baseURL = savedURL ?? NSURL(string: "https://api.github.com")!
        accessToken = UICKeyChainStore.stringForKey(UICKeychainAccessTokenKey)
    }

    private func call(path: String, handler: (response: AnyObject?, error: NSError?) -> Void) {
        if accessToken == nil {
            return
        }

        let request = NSMutableURLRequest()
        request.URL = baseURL.URLByAppendingPathComponent(path)
        request.setValue("token \(accessToken!)", forHTTPHeaderField: "Authorization")
        request.cachePolicy = .ReloadIgnoringLocalAndRemoteCacheData

        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, connectionError in
            if connectionError != nil {
                handler(response: nil, error: connectionError)
                return
            }

            var parseError: NSError?
            let JSONObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data,
                options: nil,
                error: &parseError)

            if parseError != nil {
                handler(response: nil, error: connectionError)
                return;
            }

            handler(response: JSONObject, error: nil)
        }

        task.resume()
    }

    func fetchNotifications() {
        call("/notifications") { response, error in
            if error != nil {
                self.delegate?.github(self, didReceiveError: error!)
                return;
            }

            if let dictionaries = response as? [NSDictionary] {
                for dictionary in dictionaries {
                    if let notification = Notification(dictionary: dictionary) {
                        self.delegate?.github(self, didReceiveNotification: notification)
                    }
                }
            }
        }
    }

    func fetchHTMLURLFromAPIPath(APIPath: String, handler: (URL: NSURL) -> Void) {
        var path = APIPath
        if let basePath = baseURL.path {
            // trim /api/v3 from APIPath for gh:e
            path = path.stringByReplacingOccurrencesOfString(basePath,
                withString: "",
                options: .LiteralSearch,
                range: nil)
        }

        call(path) { response, error in
            if error != nil {
                self.delegate?.github(self, didReceiveError: error!)
                return;
            }

            if let dictionary = response as? NSDictionary {
                if let string = dictionary["html_url"] as? String {
                    if let URL = NSURL(string: string) {
                        handler(URL: URL)
                    }
                }
            }
        }
    }

    func saveCurrentConfiguration() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(baseURL.absoluteString, forKey: NSUserDefaultsBaseURLKey)
        userDefaults.synchronize()

        UICKeyChainStore.setString(accessToken, forKey: UICKeychainAccessTokenKey)
    }
}
