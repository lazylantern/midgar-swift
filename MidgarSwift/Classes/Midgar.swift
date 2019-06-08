import UIKit

// ----------------------------------
// MARK: Constants
// ----------------------------------

fileprivate struct Const {
    
    static let LogsEnabled = false
    static let DetectionFrequency = 0.5 // in seconds
    static let UploadFrequency = 60.0 // in seconds
    static let BaseUrl = "https://midgar-flask.herokuapp.com/api"
    static let EventTypeImpression = "impression"
    static let EventTypeForeground = "foreground"
    static let EventTypeBackground = "background"
    
}

// ----------------------------------
// MARK: Logger
// ----------------------------------

private class MidgarLogger: NSObject {
    
    static func log(_ message:String) {
        guard Const.LogsEnabled else { return }
        print("Midgar Log: " + message)
    }
    
}

// ----------------------------------
// MARK: Window
// ----------------------------------


public class MidgarWindow: UIWindow {
    
    fileprivate var currentScreen = ""
    fileprivate var eventBatch: [Event] = []
    fileprivate var eventUploadTimer: Timer?
    fileprivate var screenDetectionTimer: Timer?
    fileprivate let eventUploadService = EventUploadService()
    fileprivate var appToken = ""
    fileprivate var deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
    fileprivate var started = false
    fileprivate var uploadTimerLoopCount = 0
    
    public func start(appToken: String) {
        guard !started else { return }
        
        started = true
        self.appToken = appToken
        subscribeToNotifications()
        checkAppEnabled()
    }
    
    public func stop() {
        stopMonitoring()
    }
    
    private func checkAppEnabled() {
        eventUploadService.checkKillSwitch(appToken: appToken) { (data, response, error) in
            DispatchQueue.main.async {
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode == 200 {
                    self.startMonitoring()
                } else {
                    self.stopMonitoring()
                }
            }
        }
    }
    
    private func startMonitoring() {
        guard screenDetectionTimer == nil && eventUploadTimer == nil else { return }
        
        screenDetectionTimer = Timer.scheduledTimer(withTimeInterval: Const.DetectionFrequency, repeats: true, block: { (_) in
            let currentScreen = UIApplication.topViewControllerDescription()
            
            if currentScreen != self.currentScreen {
                self.currentScreen = currentScreen
                self.eventBatch.append(Event(type: Const.EventTypeImpression,
                                             screen: currentScreen,
                                             deviceId: self.deviceId))
            }
        })
        
        eventUploadTimer = Timer.scheduledTimer(withTimeInterval: Const.UploadFrequency, repeats: true, block: { (_) in
            self.uploadEventsIfNeeded()
        })
    }
    
    private func uploadEventsIfNeeded() {
        if self.eventBatch.count > 0 {
            MidgarLogger.log("Uploading \(eventBatch.count) events.")
            self.eventUploadService.uploadBatch(events: self.eventBatch, appToken: self.appToken)
            self.eventBatch = []
        } else {
            MidgarLogger.log("No event to upload.")
        }
    }
    
    private func stopMonitoring() {
        screenDetectionTimer?.invalidate()
        eventUploadTimer?.invalidate()
        screenDetectionTimer = nil
        eventUploadTimer = nil
        unsubscribeFromNotifications()
        started = false
    }
    
    private func subscribeToNotifications() {
        unsubscribeFromNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(appForegrounded(_:)),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appBackgrounded(_:)),
                                               name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    private func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func appForegrounded(_ notif: Notification) {
        self.eventBatch.append(Event(type: Const.EventTypeForeground,
                                     screen: "",
                                     deviceId: deviceId))
    }
    
    @objc private func appBackgrounded(_ notif: Notification) {
        self.eventBatch.append(Event(type: Const.EventTypeBackground,
                                     screen: "",
                                     deviceId: deviceId))
        uploadEventsIfNeeded()
    }
    
}

// ----------------------------------
// MARK: EventUploadService
// ----------------------------------


private class EventUploadService: NSObject {
    
    func checkKillSwitch(appToken: String, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let parameters: [String: Any] = ["app_token": appToken]
        let url = Const.BaseUrl + "/apps/kill"
        guard let request = createPostRequest(url: url, parameters: parameters) else { return }
        URLSession.shared.dataTask(with: request, completionHandler: completion).resume()
    }
    
    func uploadBatch(events: [Event], appToken: String) {
        let parameters: [String: Any] = ["events": events.map { $0.toDict() }, "app_token": appToken]
        let url = Const.BaseUrl + "/events"
        guard let request = createPostRequest(url: url, parameters: parameters) else { return }
        URLSession.shared.dataTask(with: request).resume() // TODO: retry if failed.
    }
    
    func createPostRequest(url: String, parameters: [String: Any]) -> URLRequest? {
        guard let url = URL(string: url) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        guard let body = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            return nil
        }
        request.httpBody = body
        return request
    }
    
}

// ----------------------------------
// MARK: Event Model
// ----------------------------------

private struct Event {
    
    let type: String
    let screen: String
    let deviceId: String
    let timestamp: Int
    
    init(type: String, screen: String, deviceId: String) {
        self.type = type
        self.screen = screen
        self.deviceId = deviceId
        timestamp = Date().timestamp
        log()
    }
    
    func toDict() -> [String: Any] {
        return ["type": type, "screen": screen, "timestamp": timestamp]
    }
    
    func log() {
        MidgarLogger.log("event: \(type), screen \(screen), id \(deviceId), timestamp \(timestamp)")
    }
    
}

// ----------------------------------
// MARK: Extensions
// ----------------------------------


private extension UIApplication {
    
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            if let visible = navigationController.visibleViewController {
                return topViewController(controller: visible)
            }
        }
        
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        
        return controller
    }
    
    class func topViewControllerDescription() -> String {
        if let topVC = topViewController() {
            return "\(type(of: topVC))"
        } else {
            return ""
        }
    }
    
}

private extension Date {
    
    var timestamp: Int {
        return Int(truncatingIfNeeded: Int64((self.timeIntervalSince1970 * 1000.0).rounded()))
    }
    
}
