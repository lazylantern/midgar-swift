# MidgarSwift

## Requirements

iOS > 10.0

Objective-C SDK is available at https://github.com/lazylantern/midgar-objc.git.

## Installation

Midgar is available through CocoaPods. 

To install it, simply add the following line to your Podfile:

```ruby
pod 'MidgarSwift', :git => 'https://github.com/lazylantern/midgar-swift.git'
```

Run `pod install`.

The integration entirely happens in the `AppDelegate.swift` implementation file.

Import the header file:

```
#import "Midgar.h"
```

Declare the `midgarWindow` property:

```
@interface AppDelegate ()

@property (nonatomic, strong) MidgarWindow *midgarWindow;

@end
```

Add a getter for the `window` property:

```
@implementation AppDelegate

- (UIWindow *)window {
if (!self.midgarWindow) {
self.midgarWindow = [[MidgarWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
}

return self.midgarWindow;
}
```

Start the Midgar SDK:

```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

[self.midgarWindow startWithAppToken:@"your-app-token-provided-by-lazy-lantern"];

return YES;
}
```

You're done!

## Author

SDK edited by Lazy Lantern inc. 

For any assitance or trouble shouting, please contact us at founders@lazylantern.com.

## License

Midgar is available under the Apache license. See the LICENSE file for more info.
