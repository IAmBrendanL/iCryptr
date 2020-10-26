//
//  ThumbnailProvider.swift
//  PeopleGroupThumbnail
//
//  Created by Matt Neuburg on 10/19/19.
//  Copyright © 2019 Matt Neuburg. All rights reserved.
//

import UIKit
import AVFoundation
import QuickLookThumbnailing
import os.log


extension CGRect {
    init(_ x:CGFloat, _ y:CGFloat, _ w:CGFloat, _ h:CGFloat) {
        self.init(x:x, y:y, width:w, height:h)
    }
}
extension CGSize {
    init(_ width:CGFloat, _ height:CGFloat) {
        self.init(width:width, height:height)
    }
}
extension CGPoint {
    init(_ x:CGFloat, _ y:CGFloat) {
        self.init(x:x, y:y)
    }
}
extension CGVector {
    init (_ dx:CGFloat, _ dy:CGFloat) {
        self.init(dx:dx, dy:dy)
    }
}

let mylog = OSLog(subsystem: "thumbnailExtension", category: "testing")

class ThumbnailProvider: QLThumbnailProvider {
    
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        
        // simple solution: provide the same thumbnail, all the time, as an image file
        
//        os_log("here", log: mylog, type: .debug)
//
//        let url = Bundle.main.url(forResource: "smiley", withExtension: "jpg")!
//        let reply = QLThumbnailReply(imageFileURL: url)
//        handler(reply, nil)
//        return;
        
        // however, that's not very sophisticated or very interesting
        // let's actually _read_ the incoming request and actually _draw_ an appropriate thumbnail
        print("thumbnail")
        let furl = request.fileURL
        let name = furl.deletingPathExtension().lastPathComponent
        
        var data: Data? = nil
        
        do {
            data = try Data(contentsOf: request.fileURL as URL)
        } catch {
            print("Unable to load data: \(error)")
            
            return
        }

        let im = UIImage.init(blurHash: extractThumbnail(data!)!, size: CGSize(width: 32, height: 32))
        let maxsz = request.maximumSize
        let r = AVMakeRect(aspectRatio: im!.size, insideRect: CGRect(origin:.zero, size:maxsz))

//        let att = NSAttributedString(string:name, attributes:[.font:UIFont(name:"Georgia", size:14)!, .foregroundColor:UIColor.white])
//        let attsz = att.size()
        
        // if you draw using the context parameter, note that it is flipped
        /*
        func draw(_ con:CGContext) -> Bool {
            let bounds = con.boundingBoxOfClipPath
            UIGraphicsPushContext(con)
            con.translateBy(x: 0, y: bounds.height)
            con.scaleBy(x: 1, y: -1)
            im.draw(in: bounds)
            att.draw(at: CGPoint((bounds.width-attsz.width)/2, (bounds.height-attsz.height)/2))
            UIGraphicsPopContext()
            return true
        }
 */
        func draw() -> Bool {
            im!.draw(in: CGRect(origin:.zero, size:r.size))
            return true
        }
        
        // let reply = QLThumbnailReply(contextSize: r.size, drawing: draw)
        let reply2 = QLThumbnailReply(contextSize: r.size, currentContextDrawing: draw)
        print(reply2)
        handler(reply2,nil)
        
        
    }
}

