import Photos

public typealias PhotosCompletion = (_ collection: PHAssetCollection?) -> Void
public typealias PhotosAddImageCompletion = (_ assetPlaceholder: PHObjectPlaceholder?, _ error: Error?) -> Void

extension PHAssetCollection {
    public class func saveImageToAlbum(image: UIImage, albumName: String, completion: PhotosAddImageCompletion?) {
        self.findOrCreateAlbum(name: albumName) { (collection) -> Void in
            if let collection = collection {
                collection.addImage(image, completion: completion)
            } else {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                completion?(nil, nil)
            }
        }
    }
    
    public class func findOrCreateAlbum(name: String, completion: PhotosCompletion?) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", name)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        if let first = collection.firstObject {
            completion?(first)
        } else {
            var assetCollectionPlaceholder : PHObjectPlaceholder!
            PHPhotoLibrary.shared().performChanges({
                let createAlbumRequest : PHAssetCollectionChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
                assetCollectionPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
            }, completionHandler: { success, error in
                DispatchQueue.main.async {
                    if (success) {
                        let collectionFetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [assetCollectionPlaceholder.localIdentifier], options: nil)
                        completion?(collectionFetchResult.firstObject)
                    } else {
                        completion?(nil)
                    }
                }
            })
        }
    }
    
    public func addImage(_ image: UIImage, completion: PhotosAddImageCompletion?) {
        var assetPlaceholder : PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
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
    
    public class func fetchLastPhoto(resizeTo size: CGSize?, contentMode: PHImageContentMode = .default, completion: ((UIImage?) -> Void)?) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        if let lastAsset = fetchResult.lastObject {
            PHImageManager.default().requestImage(for: lastAsset, targetSize: size!, contentMode: contentMode, options: PHImageRequestOptions(), resultHandler: { (result, info) in
                DispatchQueue.main.async() {
                    completion?(result)
                }
            })
        } else {
            DispatchQueue.main.async() {
                completion?(nil)
            }
        }
    }
}
