import UIKit
import AVFoundation

protocol CaptureVideoPreviewDelegate {
    func captureColorInCaptureDevicePointOfInterest(point: CGPoint)
}

open class CameraView: UIView {

    var session: AVCaptureSession!
    var input: AVCaptureDeviceInput!
    var device: AVCaptureDevice!
    var imageOutput: AVCaptureStillImageOutput!
    var preview: AVCaptureVideoPreviewLayer!
    let cameraQueue = DispatchQueue(label: "net.djcp.CameraViewController.Queue")
    
    //let focusView = CropOverlay(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
    public var currentPosition = AVCaptureDevicePosition.back
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        preview?.frame = self.bounds
    }
    
    open func startSession() {
        session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetPhoto
        
        device = cameraWithPosition(currentPosition)
        if let device = device, device.hasFlash {
            do {
                try device.lockForConfiguration()
                device.flashMode = .auto
                device.unlockForConfiguration()
            } catch _ {}
        }
        
        let outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        
        do {
            input = try AVCaptureDeviceInput(device: device)
        } catch let error as NSError {
            input = nil
            print("Error: \(error.localizedDescription)")
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        imageOutput = AVCaptureStillImageOutput()
        imageOutput.outputSettings = outputSettings
        
        session.addOutput(imageOutput)
        
        cameraQueue.async {
            self.session?.startRunning()
            DispatchQueue.main.async() {
                self.createPreview()
            }
        }
    }
    
    public func stopSession() {
        cameraQueue.async {
            self.session?.stopRunning()
            self.preview?.removeFromSuperlayer()
            self.session = nil
            self.input = nil
            self.imageOutput = nil
            self.preview = nil
            self.device = nil
        }
    }
    
    func createPreview() {
        preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = AVLayerVideoGravityResizeAspectFill
        preview.frame = bounds
        let statusBarOrientation = UIApplication.shared.statusBarOrientation
        var videoOrientation = AVCaptureVideoOrientation.portrait
        if statusBarOrientation != .unknown {
            videoOrientation = AVCaptureVideoOrientation(rawValue: statusBarOrientation.rawValue)!
        }
        preview.connection.videoOrientation = videoOrientation
        self.layer.addSublayer(preview)
    }
    
    func cameraWithPosition(_ position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        guard let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice] else {
            return nil
        }
        return devices.filter { $0.position == position }.first
    }
    
    public func rotatePreview() {
        guard preview != nil else {
            return
        }
        switch UIApplication.shared.statusBarOrientation {
        case .portrait:
            preview?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
            break
        case .portraitUpsideDown:
            preview?.connection.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
            break
        case .landscapeRight:
            preview?.connection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
            break
        case .landscapeLeft:
            preview?.connection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
            break
        default: break
        }
    }
    
    public func switchCamera() {
        guard let session = session, let input = input else {
            return
        }
        
        session.beginConfiguration()
        session.removeInput(input)
        
        if input.device.position == AVCaptureDevicePosition.back {
            currentPosition = AVCaptureDevicePosition.front
            device = cameraWithPosition(currentPosition)
        } else {
            currentPosition = AVCaptureDevicePosition.back
            device = cameraWithPosition(currentPosition)
        }
        
        guard let i = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        self.input = i
        
        session.addInput(i)
        session.commitConfiguration()
    }
    
    public func takePicture(completion: @escaping TakePictureCompletion) {
        cameraQueue.sync {
            let orientation = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue)!
            guard let videoConnection: AVCaptureConnection = self.imageOutput.connection(withMediaType: AVMediaTypeVideo) else {
                completion(nil)
                return
            }
            
            videoConnection.videoOrientation = orientation
            self.imageOutput.captureStillImageAsynchronously(from: videoConnection, completionHandler: { buffer, error in
                guard let buffer = buffer,
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer),
                    let image = UIImage(data: imageData) else {
                        completion(nil)
                        return
                }
                DispatchQueue.main.async() {
                    completion(image)
                }
            })
        }
    }
    
    public func toggleFlash() {
        guard let device = device, device.hasFlash else {
            return
        }
        
        do {
            try device.lockForConfiguration()
            if device.flashMode == .on {
                device.flashMode = .off
            } else if device.flashMode == .off {
                device.flashMode = .auto
            } else {
                device.flashMode = .on
            }
            device.unlockForConfiguration()
        } catch _ { }
    }
}
