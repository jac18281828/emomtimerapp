# EMOM Timer iOS App

A simple iOS app that displays the EMOM (Every Minute on the Minute) Timer web application in a native WebKit view.

## Features

- Native iOS wrapper for the EMOM Timer web application
- Full-screen WebKit view for optimal workout experience
- Supports both iPhone and iPad
- Portrait and landscape orientations

## Requirements

- iOS 15.0 or later
- Xcode 14.0 or later
- Swift 5.0

## Building

1. Open `EMOMTimer.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run the project (⌘R)

## App Store Preparation

Before submitting to the App Store:

1. Add app icons in `EMOMTimer/Assets.xcassets/AppIcon.appiconset/`
2. Update the `DEVELOPMENT_TEAM` in the project settings with your Apple Developer Team ID
3. Update `PRODUCT_BUNDLE_IDENTIFIER` if needed (currently set to `com.emomtimer.app`)
4. Add appropriate privacy descriptions in `Info.plist` if required
5. Test thoroughly on physical devices

## License

This project is licensed under the BSD-3-Clause License - see the [LICENSE](LICENSE) file for details.

## Credits

EMOM Timer web application: http://emom-timer-us-east-2-504242000181.s3-website.us-east-2.amazonaws.com
