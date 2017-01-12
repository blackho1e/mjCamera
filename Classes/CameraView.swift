import UIKit
import AVFoundation
import Photos

public enum CameraOutputQuality: Int {
    case low, medium, high
}

protocol CameraViewDelegate {
    func cameraViewCloseButtonTapped()
    func cameraViewShutterButtonTapped(image: UIImage?, asset: PHAsset?)
}

open class CameraView: UIView {

    @IBOutlet weak var hLine1: UIView!
    @IBOutlet weak var hLine2: UIView!
    @IBOutlet weak var vLine1: UIView!
    @IBOutlet weak var vLine2: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var gridButton: UIButton!
    @IBOutlet weak var switchCameraButton: UIButton!
    @IBOutlet weak var takePhotoButton: UIButton!
    
    @IBOutlet weak var permissionsView: UIView!
    @IBOutlet weak var permissionTitleView: UILabel!
    @IBOutlet weak var permissionDescView: UILabel!
    @IBOutlet weak var permissionSettingsButton: UIButton!
    
    var delegate: CameraViewDelegate?
    var view: UIView!
    var session: AVCaptureSession!
    var input: AVCaptureDeviceInput!
    var device: AVCaptureDevice!
    var imageOutput: AVCaptureStillImageOutput!
    var preview: AVCaptureVideoPreviewLayer!
    let cameraQueue = DispatchQueue(label: "net.djcp.CameraViewController.Queue")
    
    var focusView = UIView(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
    open var albumName: String = ""
    open var currentPosition = AVCaptureDevicePosition.back
    open var cameraOutputQuality = CameraOutputQuality.high
    open var saveToPhoneLibrary = true
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        prepareView()
        checkPermissions()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepareView()
        checkPermissions()
    }
    
    func prepareView() {
        self.view = loadViewFromNib()
        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.frame = self.bounds
        self.addSubview(view)
        [
            hLine1,
            hLine2,
            vLine1,
            vLine2,
            closeButton,
            flashButton,
            gridButton,
            switchCameraButton,
            takePhotoButton,
            permissionsView
        ].forEach({ self.addSubview($0) })
        self.setNeedsUpdateConstraints()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        preview?.frame = self.bounds
    }
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        delegate?.cameraViewCloseButtonTapped()
    }
    
    @IBAction func flashButtonPressed(_ sender: Any) {
        self.toggleFlash()
    }
    
    @IBAction func gridButtonPressed(_ sender: Any) {
        self.toggleGrid()
    }
    
    @IBAction func settingsButtonPressed(_ sender: Any) {
        if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.openURL(appSettings)
        }
    }
    
    @IBAction func switchCameraButtonPressed(_ sender: Any) {
        self.switchCamera()
    }
    
    @IBAction func takePhotoButtonPressed(_ sender: Any) {
        guard let output = self.imageOutput,
            let connection = output.connection(withMediaType: AVMediaTypeVideo) else {
                return
        }
        
        if connection.isEnabled {
            toggleButtons(enabled: false)
            self.takePicture { image in
                guard let image = image else {
                    self.toggleButtons(enabled: true)
                    return
                }
                
                if self.saveToPhoneLibrary {
                    PHAssetCollection.saveImageToAlbum(image: image, albumName: self.albumName, completion: { assetPlaceholder, error in
                        self.toggleButtons(enabled: true)
                        guard let assetPlaceholder = assetPlaceholder else {
                            if !self.albumName.isEmpty {
                                self.showNoPermissionsView(library: true)
                            }
                            self.delegate?.cameraViewShutterButtonTapped(image: image, asset: nil)
                            return
                        }
                        
                        let localId = assetPlaceholder.localIdentifier
                        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localId], options: nil)
                        if let asset = assets.firstObject {
                            self.delegate?.cameraViewShutterButtonTapped(image: image, asset: asset)
                        } else {
                            self.showNoPermissionsView(library: true)
                            self.delegate?.cameraViewShutterButtonTapped(image: image, asset: nil)
                        }
                    })
                } else {
                    self.toggleButtons(enabled: true)
                    self.delegate?.cameraViewShutterButtonTapped(image: image, asset: nil)
                }
            }
        }
    }
    
    private func checkPermissions() {
        if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) != .authorized {
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { granted in
                if granted {
                    if PHPhotoLibrary.authorizationStatus() != PHAuthorizationStatus.authorized {
                        PHPhotoLibrary.requestAuthorization() { _ in
                        }
                    }
                } else {
                    DispatchQueue.main.async() {
                        self.showNoPermissionsView()
                    }
                }
            }
        }
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let view = UINib(nibName: "CameraView", bundle: bundle).instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
    open func startSession() {
        session = AVCaptureSession()
        switch (cameraOutputQuality) {
        case .low:
            session.sessionPreset = AVCaptureSessionPresetLow
        case .medium:
            session.sessionPreset = AVCaptureSessionPresetMedium
        case .high:
            session.sessionPreset = AVCaptureSessionPresetPhoto
        }
        
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
    
    open func stopSession() {
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
        self.view.layer.addSublayer(preview)
        
        if let gestureRecognizers = gestureRecognizers {
            gestureRecognizers.forEach({ self.view.removeGestureRecognizer($0) })
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.focus(gesture:)))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    func cameraWithPosition(_ position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        guard let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice] else {
            return nil
        }
        return devices.filter { $0.position == position }.first
    }
    
    func showNoPermissionsView(library: Bool = false) {
        if library {
            permissionTitleView.text = "permissions.library.title".localizedWithOption(tableName: "Localizable", bundle: Bundle(for: CameraViewController.self))
            permissionDescView.text = "permissions.library.desc".localizedWithOption(tableName: "Localizable", bundle: Bundle(for: CameraViewController.self))
        } else {
            permissionTitleView.text = "permissions.title".localizedWithOption(tableName: "Localizable", bundle: Bundle(for: CameraViewController.self))
            permissionDescView.text = "permissions.desc".localizedWithOption(tableName: "Localizable", bundle: Bundle(for: CameraViewController.self))
        }
        permissionSettingsButton.setTitle("permissions.settings".localizedWithOption(tableName: "Localizable", bundle: Bundle(for: CameraViewController.self)), for: UIControlState())
        view.isHidden = true
        permissionsView.isHidden = false
    }
    
    open func rotatePreview() {
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
        switch UIDevice.current.orientation {
        case .portrait:
            updateToRotation(angle: 0)
            break
        case .portraitUpsideDown:
            updateToRotation(angle: 180)
            break
        case .landscapeRight:
            updateToRotation(angle: 270)
            break
        case .landscapeLeft:
            updateToRotation(angle: 90)
            break
        default:
            break
        }
    }
    
    open func switchCamera() {
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
        
        flashButton.isHidden = self.currentPosition == .front
    }
    
    open func takePicture(completion: @escaping TakePictureCompletion) {
        cameraQueue.sync {
            let orientation = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue)!
            guard let videoConnection: AVCaptureConnection = self.imageOutput.connection(withMediaType: AVMediaTypeVideo) else {
                DispatchQueue.main.async() {
                    completion(nil)
                }
                return
            }
            
            videoConnection.videoOrientation = orientation
            self.imageOutput.captureStillImageAsynchronously(from: videoConnection, completionHandler: { buffer, error in
                guard let buffer = buffer,
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer),
                    let image = UIImage(data: imageData) else {
                        DispatchQueue.main.async() {
                            completion(nil)
                        }
                        return
                }
                DispatchQueue.main.async() {
                    completion(image)
                }
            })
        }
    }
    
    func toggleButtons(enabled: Bool) {
        [
            closeButton,
            flashButton,
            gridButton,
            switchCameraButton,
            takePhotoButton
        ].forEach({ $0.isEnabled = enabled })
    }
    
    open func toggleFlash() {
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
        
        let imageName: String
        switch device.flashMode {
        case .auto:
            imageName = "flash_auto"
        case .on:
            imageName = "flash_on"
        case .off:
            imageName = "flash_off"
        }
        let image = UIImage(named: imageName, in: Bundle(for: type(of: self)), compatibleWith: nil)
        flashButton.setImage(image, for: UIControlState())
    }
    
    open func toggleGrid() {
        if hLine1.alpha == 0.0 {
            hLine1.alpha = 0.2
            hLine2.alpha = 0.2
            vLine1.alpha = 0.2
            vLine2.alpha = 0.2
            let image = UIImage(named: "grid_off", in: Bundle(for: CameraViewController.self), compatibleWith: nil)
            gridButton.setImage(image, for: .normal)
        } else {
            hLine1.alpha = 0.0
            hLine2.alpha = 0.0
            vLine1.alpha = 0.0
            vLine2.alpha = 0.0
            let image = UIImage(named: "grid_on", in: Bundle(for: CameraViewController.self), compatibleWith: nil)
            gridButton.setImage(image, for: .normal)
        }
    }
    
    fileprivate func updateToRotation(angle: CGFloat) {
        UIView.animate(withDuration: 0.5, animations: {
            let angle = CGFloat(M_PI / 180.0) * angle
            self.closeButton.transform = CGAffineTransform(rotationAngle: angle)
            self.flashButton.transform = CGAffineTransform(rotationAngle: angle)
            self.gridButton.transform = CGAffineTransform(rotationAngle: angle)
            self.switchCameraButton.transform = CGAffineTransform(rotationAngle: angle)
            self.takePhotoButton.transform = CGAffineTransform(rotationAngle: angle)
        })
    }
}

extension CameraView {
    
    internal func focus(gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self)
        let viewsize = self.bounds.size
        let newPoint = CGPoint(x: point.y / viewsize.height, y: 1.0 - point.x / viewsize.width)
        
        guard let device = device, device.isFocusModeSupported(.continuousAutoFocus) else {
            return
        }
        
        do {
            try device.lockForConfiguration()
        } catch _ {
            return
        }
        
        device.focusMode = AVCaptureFocusMode.continuousAutoFocus
        device.exposurePointOfInterest = newPoint
        device.exposureMode = AVCaptureExposureMode.continuousAutoExposure
        device.unlockForConfiguration()
        
        self.focusView.alpha = 0.5
        self.focusView.center = point
        self.focusView.clipsToBounds = true
        self.focusView.backgroundColor = UIColor.clear
        self.focusView.layer.borderColor = UIColor(rgb: 0xe0e0e0).cgColor
        self.focusView.layer.borderWidth = 1.0
        self.focusView.layer.cornerRadius = 6
        self.focusView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        self.view.addSubview(self.focusView)
        
        UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 3.0, options: UIViewAnimationOptions.curveEaseIn,
                       animations: {
                        self.focusView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }, completion: {(finished) in
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.3,
                           initialSpringVelocity: 3.0, options: UIViewAnimationOptions.curveEaseIn,
                           animations: {
                            self.focusView.alpha = 1.0
                            self.focusView.layer.borderColor = UIColor(rgb: 0x52ce90).cgColor
            }, completion: {(finished) in
                self.focusView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                self.focusView.removeFromSuperview()
            })
        })
    }
}
