# MidgarSwift

## Requirements

iOS >= 10.0

Objective-C SDK is available at https://github.com/lazylantern/midgar-objc.git.

## Installation

Midgar is available through CocoaPods and Carthage. 

### CocoaPods Setup

1. Add the source and pod to your Podfile as follow:

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

2. Run `pod install`.

### Carthage Setup

1. Add `github "lazylantern/midgar-swift"` to your Cartfile.

2. Run `carthage update`.

3. Drag the built framework at `Carthage/Build/iOS/Midgar.framework` into your linked frameworks (Xcode Project > [Your Application Target] > General > Linked Frameworks and Libraries).

Go to Xcode Project > [Your Application Target] > Build Phases. 

If using Carthage for the first time, click the + icon and choose New Run Script Phase. In the script area below the shell, add `/usr/local/bin/carthage copy-frameworks`.

4. Add `$(SRCROOT)/Carthage/Build/iOS/Midgar.framework` under “Input Files".

### Integration

The integration entirely happens in the `AppDelegate.swift` implementation file.

1. Import the module:

```
import MidgarSwift
```

2. Declare the `midgarWindow` variable and modify the `window` property getter to return the `midgarWindow`:

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

3. Start the Midgar SDK in the `applicationDidFinishLaunchingWithOptions` method:

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
