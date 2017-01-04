import UIKit
import mjCamera
import Photos

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func cameraButtonPressed(_ sender: Any) {
        let cameraViewController = CameraViewController() { image, asset in
            guard let _ = image else {  //cancel
                self.dismiss(animated: true, completion: nil)
                return
            }
        }
        cameraViewController.albumName = "mjCamera"
        present(cameraViewController, animated: true, completion: nil)
    }
}
