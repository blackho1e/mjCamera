import UIKit
import AVFoundation
import Photos

public class CameraViewController: UIViewController {

    @IBOutlet weak var cameraView: CameraView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var gridButton: UIButton!
    @IBOutlet weak var switchCameraButton: UIButton!
    @IBOutlet weak var takePhotoButton: UIButton!
    @IBOutlet weak var gridView: UIView!
    @IBOutlet weak var permissionsView: UIView!
    @IBOutlet weak var permissionTitleView: UILabel!
    @IBOutlet weak var permissionDescView: UILabel!
    @IBOutlet weak var permissionSettingsButton: UIButton!
    
    private var onCompletion: CameraViewControllerCompletion?
    open var albumName: String = ""
    
    public init(completion: @escaping CameraViewControllerCompletion) {
        super.init(nibName: nil, bundle: nil)
        onCompletion = completion
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    open override func loadView() {
        super.loadView()
        if let view = UINib(nibName: "CameraViewController", bundle: Bundle(for: self.classForCoder))
                        .instantiate(withOwner: self, options: nil).first as? UIView {
            self.view = view
        }
        self.view.backgroundColor = UIColor.black
        [gridView,
         closeButton,
         flashButton,
         gridButton,
         switchCameraButton,
         takePhotoButton,
         permissionsView
        ].forEach({ self.view.addSubview($0) })
        view.setNeedsUpdateConstraints()
    }
    
    open override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        get {
            return .portrait
        }
    }
    
    open override var shouldAutorotate: Bool {
        get {
            return false
        }
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return .portrait
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(rotateCameraView(_:)),
                                               name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        checkPermissions()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        cameraView?.startSession()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        cameraView?.stopSession()
    }
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        onCompletion?(nil, nil)
    }
    
    @IBAction func flashButtonPressed(_ sender: Any) {
        self.toggleFlash()
    }
    
    @IBAction func gridButtonPressed(_ sender: Any) {
        self.togleGrid()
    }
    
    @IBAction func settingsButtonPressed(_ sender: Any) {
        if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.openURL(appSettings)
        }
    }
    
    @IBAction func switchCameraButton(_ sender: Any) {
        cameraView.switchCamera()
        flashButton.isHidden = cameraView.currentPosition == AVCaptureDevicePosition.front
    }
    
    @IBAction func takePhotoButtonPressed(_ sender: Any) {
        self.takePhoto { image, asset in
            self.onCompletion?(image, asset)
        }
    }
    
    private func checkPermissions() {
        if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) != .authorized {
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { granted in
                DispatchQueue.main.async() {
                    if !granted {
                        self.showNoPermissionsView()
                    }
                }
            }
        }
    }
    
    func rotateCameraView(_ notification: Notification) {
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
        //cameraView.rotatePreview()
    }
    
    func showNoPermissionsView() {
        permissionTitleView.text = "permissionsTitle".localizedWithOption(tableName: "Localizable", bundle: Bundle(for: CameraViewController.self))
        permissionDescView.text = "permissionsDesc".localizedWithOption(tableName: "Localizable", bundle: Bundle(for: CameraViewController.self))
        permissionSettingsButton.setTitle("permissionsSettings".localizedWithOption(tableName: "Localizable", bundle: Bundle(for: CameraViewController.self)), for: UIControlState())
        permissionsView.isHidden = false
    }
    
    open func takePhoto(completion: @escaping CameraViewControllerCompletion) {
        guard let output = cameraView.imageOutput,
            let connection = output.connection(withMediaType: AVMediaTypeVideo) else {
                return
        }
        
        if connection.isEnabled {
            toggleButtons(enabled: false)
            cameraView.takePicture { image in
                guard let image = image else {
                    self.toggleButtons(enabled: true)
                    return
                }
                
                PHAssetCollection.saveImageToAlbum(image: image, albumName: self.albumName, completion: { assetPlaceholder, error in
                    let localId = assetPlaceholder?.localIdentifier
                    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localId!], options: nil)
                    if let asset = assets.firstObject {
                        self.toggleButtons(enabled: true)
                        completion(image, asset)
                    } else {
                        self.showNoPermissionsView()
                        completion(image, nil)
                    }
                })
            }
        }
    }
    
    private func toggleButtons(enabled: Bool) {
        [closeButton,
         flashButton,
         gridButton,
         switchCameraButton,
         takePhotoButton].forEach({ $0.isEnabled = enabled })
    }
    
    open func toggleFlash() {
        guard let device = cameraView.device else {
            return
        }
        
        cameraView.toggleFlash()
        
        let imageName: String
        switch device.flashMode {
        case .auto:
            imageName = "flash_auto"
        case .on:
            imageName = "flash_on"
        case .off:
            imageName = "flash_off"
        }
        
        let image = UIImage(named: imageName, in: Bundle(for: CameraViewController.self), compatibleWith: nil)
        flashButton.setImage(image, for: UIControlState())
    }
    
    open func togleGrid() {
        if gridView.alpha == 0.0 {
            gridView.alpha = 1.0
            let image = UIImage(named: "grid_off", in: Bundle(for: CameraViewController.self), compatibleWith: nil)
            gridButton.setImage(image, for: .normal)
        } else {
            gridView.alpha = 0.0
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
