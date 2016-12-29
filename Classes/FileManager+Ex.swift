import UIKit

class FileManager {
    
    class func saveImageData(_ imageData: Data) -> String? {
        let date = Date()
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH-mm-ss"
        
        let fileManager = Foundation.FileManager.default
        let directoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let dateString = dateFormatter.string(from: date)
        var file = "\(dateString).jpg"
        var filePath = "\(directoryPath)/\(file)"
        var count = 1
        
        while fileManager.fileExists(atPath: filePath) && count < 10 {
            file = "\(dateString)_\(count).jpg"
            filePath = "\(directoryPath)/\(file)"
            count += 1
        }
        
        fileManager.createFile(atPath: filePath, contents: imageData, attributes: nil)
        return file
    }
}
