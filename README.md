# MidgarSwift

## Requirements

iOS > 10.0

Objective-C SDK is available at https://github.com/lazylantern/midgar-objc.git.

## Installation

Midgar is available through CocoaPods. 

To install it, add the source and pod to your Podfile as follow:

```ruby
platform :ios, 'x.0'

# Your other sources...
source 'https://github.com/lazylantern/MidgarSwiftPodSpecs.git' # Add this line (1 out of 2).

target 'your-app-name' do
    use_frameworks!

    # Your other pods...
    pod 'MidgarSwift' # Add this line (2 out of 2).
    
end
```

Run `pod install`.

The integration entirely happens in the `AppDelegate.swift` implementation file.

Import the module:

```
import MidgarSwift
```

Declare the `midgarWindow` variable and modify the `window` property getter to return the `midgarWindow`:

```
class AppDelegate: UIResponder, UIApplicationDelegate {

    var midgarWindow: MidgarWindow?
    var window: UIWindow? {
        get {
            midgarWindow = midgarWindow ?? MidgarWindow(frame: UIScreen.main.bounds)
            return midgarWindow
        }
        set { }
    }
    
```

Start the Midgar SDK in the `applicationDidFinishLaunchingWithOptions` method:

```
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    midgarWindow?.start(appToken: "your-app-token-provided-by-lazy-lantern") // Add this line.
    
    return true
}
```

You're done!

## Author

SDK edited by Lazy Lantern inc. 

For any assitance or trouble shouting, please contact us at founders@lazylantern.com.

## License

Midgar is available under the Apache license. See the LICENSE file for more info.
