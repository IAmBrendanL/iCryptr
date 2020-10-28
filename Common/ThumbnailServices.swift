
//
//  EncryptionServices.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 2/11/18.
//  Copyright © 2018 Brendan Lindsey. All rights reserved.
//

import Foundation
import UIKit

import QuickLookThumbnailing

let thumbnailStringSeperator = "><"
let blurHashWidth = 4

func extractThumbnail(_ fileURL: URL) -> UIImage? {
    if #available(iOS 13.4, *) {
        let file: FileHandle
        let thumbnailString: String
            
        do {
            file = try FileHandle(forReadingFrom: fileURL)
            
            try file.seek(toOffset: UInt64(saltSize + kCCBlockSizeAES128))
            let filenameAndTypeLen: Int = try file.read(upToCount: 1)!.withUnsafeBytes({ $0.pointee })
            
            try file.seek(toOffset: UInt64(ivEnd + 1 + filenameAndTypeLen))
            let thumbLen: Int = try file.read(upToCount: 1)!.withUnsafeBytes({ $0.pointee })
            
            try file.seek(toOffset: UInt64(ivEnd + 1 + filenameAndTypeLen + 1))
            let thumbData = try file.read(upToCount: thumbLen)!
            
            file.closeFile()
            
            thumbnailString = String(decoding: thumbData, as: UTF8.self)
            
            NSLog("extractThumbnail - \(fileURL.lastPathComponent) - blurHash extracted \(thumbnailString)" )
        } catch {NSLog("extractThumbnail - \(fileURL.lastPathComponent) - file ops error \(error)"); return nil}
        
        let split = thumbnailString.components(separatedBy: thumbnailStringSeperator)
        let blurHash = split[0]
        let aspectString = split.count == 2 ? split[1] : nil
        
        let aspectRatio = aspectString != nil ? (aspectString! as NSString).floatValue : 1
        
        let thumbnailWidth = 50
        let thumbnailHeight = Int(Float(thumbnailWidth) * aspectRatio)
        let im = UIImage.init(blurHash: blurHash, size: CGSize(width: thumbnailWidth, height: thumbnailHeight))

        if(im == nil) {NSLog("extractThumbnail - \(fileURL.lastPathComponent) - image creation failed \(fileURL)  \(thumbnailString)"); return nil}
        
        return im
    } else { NSLog("extractThumbnail - \(fileURL.lastPathComponent) - iOS version failure"); return nil}
}

func createThumbnail(_ fileURL: URL, completion: @escaping (String) -> Void) {
    let thumbnailWidth = 50
    let thumbnailHeight = thumbnailWidth
    
    let previewGenerator = QLThumbnailGenerator()
    let request = QLThumbnailGenerator.Request(fileAt: fileURL, size: CGSize(width: thumbnailWidth, height: thumbnailHeight), scale: CGFloat(1), representationTypes: .thumbnail)
    
    previewGenerator.generateBestRepresentation(for: request) { (thumbnail, error) in
        if let error = error {
            print(error.localizedDescription)
        } else if let thumb = thumbnail {
            let aspectRatio = Float(thumb.uiImage.size.height / thumb.uiImage.size.width)
            let blurHashHeight = min(Int(Float(blurHashWidth) * aspectRatio), 9)
            
            let thumbnailString = thumb.uiImage.blurHash(numberOfComponents: (blurHashWidth, blurHashHeight))! + thumbnailStringSeperator + aspectRatio.description
            
            completion(thumbnailString)
        }
    }
}
