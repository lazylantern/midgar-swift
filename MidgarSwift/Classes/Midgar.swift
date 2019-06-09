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
    static let SessionIdLength = 6
    static let SessionExpiration = 10 * 60 * 1000 // 10 mins in milliseconds
    
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
            self.eventUploadService.uploadBatch(events: self.eventBatch, appToken: self.appToken) { (data, response, error) in
                DispatchQueue.main.async {
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode == 201 {
                        MidgarLogger.log("Upload successful.")
                    } else {
                        MidgarLogger.log("Upload failed.")
                    }
                }
            }
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
    
    func uploadBatch(events: [Event], appToken: String, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let parameters: [String: Any] = ["events": events.map { $0.toDict() }, "app_token": appToken]
        let url = Const.BaseUrl + "/events"
        guard let request = createPostRequest(url: url, parameters: parameters) else { return }
        URLSession.shared.dataTask(with: request, completionHandler: completion).resume() // TODO: retry if failed.
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
    let sessionId: String
    let platform: String
    let sdk: String
    let country: String
    let osVersion: String
    let appName: String
    let versionName: String
    let versionCode: String
    let deviceManufacturer: String
    let deviceModel: String
    let isEmulator: Bool
    
    init(type: String, screen: String, deviceId: String) {
        self.type = type
        self.screen = screen
        self.deviceId = deviceId
        timestamp = Date().timestamp
        sessionId = Session.sessionId
        platform = Session.platform
        sdk = Session.sdk
        country = Session.country
        osVersion = Session.osVersion
        appName = Session.appName
        versionName = Session.appVersion
        versionCode = Session.appVersionCode
        deviceManufacturer = Session.deviceManufacturer
        deviceModel = Session.deviceModel
        isEmulator = Session.isEmulator
        
        
        Session.lastEvent = self
        MidgarLogger.log("new event -> \(self.toDict())")
    }
    
    func toDict() -> [String: Any] {
        return ["type": type,
                "screen": screen,
                "device_id": deviceId,
                "timestamp": timestamp,
                "session_id": sessionId,
                "platform": platform,
                "sdk": sdk,
                "country": country,
                "os_version": osVersion,
                "app_name": appName,
                "version_name": versionName,
                "version_code": versionCode,
                "manufacturer": deviceManufacturer,
                "model": deviceModel,
                "is_emulator": isEmulator]
    }
    
}

// ----------------------------------
// MARK: Session
// ----------------------------------

private class Session: NSObject {
    
    fileprivate static var lastEvent: Event?
    
    private static var _sessionId: String?
    static var sessionId: String {
        get {
            guard let sessionId = _sessionId else { // No session id.
                let sessionId = UuidGenerator.sessionId()
                _sessionId = sessionId
                return sessionId
            }
            
            if let event = lastEvent,
                event.type == Const.EventTypeBackground,
                Date().timestamp - event.timestamp > Const.SessionExpiration { // Expired session id.
                let sessionId = UuidGenerator.sessionId()
                _sessionId = sessionId
                return sessionId
            }
            
            return sessionId // Valid session id.
        }
    }
    
    private static var _isEmulator: Bool?
    static var isEmulator: Bool {
        get {
            guard _isEmulator == nil else { return _isEmulator! }
            
            #if targetEnvironment(simulator)
            _isEmulator = true
            #else
            _isEmulator = false
            #endif
            
            return _isEmulator!
        }
    }
    
    private static var _appName: String?
    static var appName: String {
        get {
            guard _appName == nil else { return _appName! }
            
            _appName = ""
            if let name = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String {
                _appName = name
            }
            
            return _appName!
        }
    }
    
    private static var _appVersion: String?
    static var appVersion: String {
        get {
            guard _appVersion == nil else { return _appVersion! }
            
            _appVersion = ""
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                _appVersion = version
            }
            
            return _appVersion!
        }
    }
    
    private static var _appVersionCode: String?
    static var appVersionCode: String {
        get {
            guard _appVersionCode == nil else { return _appVersionCode! }
            
            _appVersionCode = ""
            if let versionCode = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String {
                _appVersionCode = versionCode
            }
            
            return _appVersionCode!
        }
    }
    
    private static var _country: String?
    static var country: String {
        get {
            guard _country == nil else { return _country! }
            
            _country = ""
            if let countryCode = (Locale.current as NSLocale).object(forKey: .countryCode) as? String {
                _country = countryCode
            }
            
            return _country!
        }
    }
    
    private static var _osVersion: String?
    static var osVersion: String {
        get {
            guard _osVersion == nil else { return _osVersion! }
            _osVersion = UIDevice.current.systemVersion
            return _osVersion!
        }
    }
    
    static var deviceManufacturer: String {
        get {
            return "Apple"
        }
    }
    
    private static var _deviceModel: String?
    static var deviceModel: String {
        get {
            guard _deviceModel == nil else { return _deviceModel! }
            
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            let identifier = machineMirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
            
            _deviceModel = identifier
            return identifier
        }
    }
    
    static var sdk: String {
        get {
            return "swift"
        }
    }
    
    static var platform: String {
        get {
            return "ios"
        }
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

private struct UuidGenerator {
    
    static func sessionId() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<Const.SessionIdLength).map{ _ in letters.randomElement()! })
    }
    
}
