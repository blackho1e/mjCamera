import UIKit
import mjCamera
import Photos

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func cameraButtonPressed(_ sender: Any) {
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
    }
}
