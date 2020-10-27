import UIKit
import AVFoundation
import QuickLookThumbnailing

let ivEnd = saltSize + kCCBlockSizeAES128
// read filenameAndTypeLen from ivEnd..<ivEnd+1 = 1
// read thumbLen from ivEnd+1+filenameAndTypeLen..<ivEnd+1+filenameAndTypeLen+1 = ivEnd+1+filenameAndTypeLen+1 - ivEnd+1+filenameAndTypeLen
// read thumb from ivEnd+1+filenameAndTypeLen+1..<ivEnd+1+filenameAndTypeLen+1+thumbLen =

class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        let im = extractThumbnail(request.fileURL)
        if(im == nil) {return}
            
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

