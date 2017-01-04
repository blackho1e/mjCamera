##mjCamera
A light weight & simple & easy camera for iOS by Swift.

[![CocoaPods](https://img.shields.io/cocoapods/v/mjCamera.svg)]()[![Swift version](https://img.shields.io/badge/swift-3.0-orange.svg)]()[![license](https://img.shields.io/github/license/mashape/apistatus.svg)]()


###Installation & Requirements

This project requires Xcode 8 to run and compiles with swift 3.0

CameraViewController is available on CocoaPods. Add the following to your Podfile:

pod 'mjCamera'


###Usage

To use this component couldn't be simpler. Add import CameraViewController to the top of you controller file.

```swift
let cameraViewController = CameraViewController() { image in
	guard let image = image else { //cancel
		self.dismiss(animated: true, completion: nil)
		return
	}
}
present(cameraViewController, animated: true, completion: nil)
```

###License
mjCamera is released under the MIT license.
See LICENSE for details.
