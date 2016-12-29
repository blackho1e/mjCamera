import UIKit
import AVFoundation

public typealias CameraViewCompletion = (UIImage?) -> Void

public class CameraViewController: UIViewController {

    @IBOutlet weak var cameraView: CameraView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var gridButton: UIButton!
    @IBOutlet weak var switchCameraButton: UIButton!
    @IBOutlet weak var takePhotoButton: UIButton!
    @IBOutlet weak var gridView: UIView!
    
    var onCompletion: CameraViewCompletion?
    
    public init(completion: @escaping CameraViewCompletion) {
        super.init(nibName: nil, bundle: nil)
        onCompletion = completion
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    open override func loadView() {
        super.loadView()
        self.view.backgroundColor = UIColor.black
        if let view = UINib(nibName: "CameraViewController", bundle: Bundle(for: self.classForCoder))
                        .instantiate(withOwner: self, options: nil).first as? UIView {
            self.view = view
        }
        [gridView,
         closeButton,
         flashButton,
         gridButton,
         switchCameraButton,
         takePhotoButton
        ].forEach({ self.view.addSubview($0) })
        view.setNeedsUpdateConstraints()
    }
    
    open override var shouldAutorotate: Bool {
        get {
            return false
        }
    }
 
    open override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(rotateCameraView),
                                               name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraView?.startSession()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraView?.stopSession()
    }
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        onCompletion?(nil)
    }
    
    @IBAction func flashButtonPressed(_ sender: Any) {
        self.toggleFlash()
    }
    
    @IBAction func gridButtonPressed(_ sender: Any) {
        self.togleGrid()
    }
    
    @IBAction func switchCameraButton(_ sender: Any) {
        cameraView.switchCamera()
        flashButton.isHidden = cameraView.currentPosition == AVCaptureDevicePosition.front
    }
    
    @IBAction func takePhotoButtonPressed(_ sender: Any) {
        self.takePhoto { image in
            self.onCompletion?(image)
        }
    }
    
    func rotateCameraView() {
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
    
    open func takePhoto(completion: @escaping TakePictureCompletion) {
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
                completion(image)
                self.toggleButtons(enabled: true)
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
