import UIKit
import mjCamera
import Photos

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func cameraButtonPressed(_ sender: Any) {
        let cameraViewController = CameraViewController() { image in
            guard let image = image else {  //cancel
                self.dismiss(animated: true, completion: nil)
                return
            }
            /*
            PHAssetCollection.saveImageToAlbum(image: image, albumName: "mjCamera", completion: { assetPlaceholder, error in
                let localId = assetPlaceholder?.localIdentifier
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localId!], options: nil)
                if let asset = assets.firstObject {
                    asset.requestContentEditingInput(with: PHContentEditingInputRequestOptions()) { (input, _) in
                        let url = input?.fullSizeImageURL
                    }
                }
                //open class func fetchAssets(withLocalIdentifiers identifiers: [String], options: PHFetchOptions?) -> PHFetchResult<PHAsset>
            })
 */
        }
        present(cameraViewController, animated: true, completion: nil)
    }
}
