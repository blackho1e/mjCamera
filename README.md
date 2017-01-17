##mjCamera
A light weight & simple & easy camera for iOS by Swift.

[![CocoaPods](https://img.shields.io/cocoapods/v/mjCamera.svg)]()
[![CocoaPods](https://img.shields.io/cocoapods/p/mjCamera.svg)]()
[![Support](https://img.shields.io/badge/support-iOS%208%2B%20-blue.svg?style=flat)](https://www.apple.com/nl/ios/)
[![Swift version](https://img.shields.io/badge/swift-3.0-orange.svg)]()
[![CocoaPods](https://img.shields.io/cocoapods/l/mjCamera.svg)]()

<img width="50%" height="50%" src="https://github.com/blackho1e/mjCamera/raw/master/preview.png" />

###Installation & Requirements

This project requires Xcode 8 to run and compiles with swift 3.0

CameraViewController is available on CocoaPods. Add the following to your Podfile:

pod 'mjCamera'


###Usage

To use this component couldn't be simpler. Add import CameraViewController to the top of you controller file.

```swift
let cameraViewController = CameraViewController(albumName: "mjCamera", saveToPhoneLibrary: true) { success, image, asset in
	if success {
                
	} else {
		guard let _ = image else {  //cancel
			self.dismiss(animated: true, completion: nil)
			return
		}
		// When the last photo button is clicked
	}
}
present(cameraViewController, animated: true, completion: nil)
```

###License
mjCamera is released under the MIT license.
See LICENSE for details.
