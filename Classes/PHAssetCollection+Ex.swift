import Photos

public typealias PhotosCompletion = (_ collection: PHAssetCollection?) -> Void
public typealias PhotosAddImageCompletion = (_ assetPlaceholder: PHObjectPlaceholder?, _ error: Error?) -> Void

extension PHAssetCollection {
    public class func saveImageToAlbum(image: UIImage, albumName: String, completion: PhotosAddImageCompletion?) {
        self.findOrCreateAlbum(name: albumName) { (collection) -> Void in
            collection?.addImage(image, completion: completion)
        }
    }
    
    public class func findOrCreateAlbum(name: String, completion: PhotosCompletion?) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", name)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        if let first = collection.firstObject {
            completion?(first)
        }else{
            var assetCollectionPlaceholder : PHObjectPlaceholder!
            PHPhotoLibrary.shared().performChanges({
                let createAlbumRequest : PHAssetCollectionChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
                assetCollectionPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
            }, completionHandler: { success, error in
                DispatchQueue.main.async {
                    if (success) {
                        let collectionFetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [assetCollectionPlaceholder.localIdentifier], options: nil)
                        completion?(collectionFetchResult.firstObject)
                    }
                    completion?(nil)
                }
            })
        }
    }
    
    public func addImage(_ image: UIImage, completion: PhotosAddImageCompletion?) {
        var assetPlaceholder : PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            /*
            if #available(iOS 9.0, *) {
                let options = PHAssetResourceCreationOptions()
                options.originalFilename = "fileName"
                let newcreation: PHAssetCreationRequest = PHAssetCreationRequest.forAsset()
                newcreation.addResource(with: .photo, data: UIImageJPEGRepresentation(image, 1)!, options: options)
                assetPlaceholder = newcreation.placeholderForCreatedAsset
            } else {
                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset
            }
            */
            let createAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            assetPlaceholder = createAssetRequest.placeholderForCreatedAsset
            if let albumChangeRequest = PHAssetCollectionChangeRequest(for: self) {
                albumChangeRequest.addAssets([assetPlaceholder!] as NSArray)
            }
        }, completionHandler: { success, error in
            DispatchQueue.main.async {
                completion?(assetPlaceholder, error)
            }
        })
    }
}
