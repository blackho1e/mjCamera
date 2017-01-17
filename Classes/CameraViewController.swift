import UIKit
import AVFoundation
import Photos

open class CameraViewController: UIViewController, CameraViewDelegate {
    
    @IBOutlet weak var cameraView: CameraView!
    var onCompletion: CameraViewControllerCompletion?
    var albumName: String = ""
    var cameraOutputQuality: CameraOutputQuality = .high
    var saveToPhoneLibrary: Bool!
    
    public init(albumName: String = "", cameraOutputQuality: CameraOutputQuality = .high,
                saveToPhoneLibrary: Bool = true, completion: @escaping CameraViewControllerCompletion) {
        super.init(nibName: nil, bundle: nil)
        self.albumName = albumName
        self.cameraOutputQuality = cameraOutputQuality
        self.saveToPhoneLibrary = saveToPhoneLibrary
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
        cameraView.albumName = self.albumName
        cameraView.cameraOutputQuality = self.cameraOutputQuality
        cameraView.saveToPhoneLibrary = self.saveToPhoneLibrary
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
        cameraView?.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(rotateCameraView(_:)),
                                               name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
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
    
    func cameraViewCloseButtonTapped() {
        self.onCompletion?(false, nil, nil)
    }
    
    func cameraViewShutterButtonTapped(image: UIImage?, asset: PHAsset?) {
        self.onCompletion?(true, image, asset)
    }
    
    func cameraViewLastPhotoButtonTapped(image: UIImage?) {
        self.onCompletion?(false, image, nil)
    }
    
    func rotateCameraView(_ notification: Notification) {
        cameraView.rotatePreview()
    }
}
