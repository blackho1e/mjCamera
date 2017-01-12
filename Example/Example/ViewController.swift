import UIKit
import mjCamera
import Photos

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func cameraButtonPressed(_ sender: Any) {
        let cameraViewController = CameraViewController(albumName: "mjCamera", saveToPhoneLibrary: false) { image, asset in
            guard let _ = image else {  //cancel
                self.dismiss(animated: true, completion: nil)
                return
            }
        }
        present(cameraViewController, animated: true, completion: nil)
    }
}
