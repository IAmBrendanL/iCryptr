import UIKit
import AVFoundation
import QuickLookThumbnailing

class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        NSLog("thumbnail gen start \(request.fileURL)" )
        var data: Data? = nil
        
        do {
            data = try Data(contentsOf: request.fileURL as URL)
        } catch {
            print("Unable to load data: \(error)")
            
            return
        }
        let blurHash = extractThumbnail(data!)
        
        if(blurHash == nil) {NSLog("thumbnail empty"); return}
        
        let im = UIImage.init(blurHash: blurHash!, size: CGSize(width: 32, height: 32))
        
        
        
        if(im == nil) {NSLog("thumbnail image creation failed \(request.fileURL)  \(blurHash!)"); return}
        NSLog("\(request.fileURL)  \(blurHash!)")
        
        let maxsz = request.maximumSize
        let r = AVMakeRect(aspectRatio: im!.size, insideRect: CGRect(origin:.zero, size:maxsz))

        func draw() -> Bool {
            im!.draw(in: CGRect(origin:.zero, size:r.size))
            return true
        }

        let reply2 = QLThumbnailReply(contextSize: r.size, currentContextDrawing: draw)

        handler(reply2, nil)
    }
}

