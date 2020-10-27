
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

func extractThumbnail(_ fileURL: URL) -> UIImage? {
    if #available(iOS 13.4, *) {
        let file: FileHandle
        let blurHash: String
            
        do {
            file = try FileHandle(forReadingFrom: fileURL)
            
            try file.seek(toOffset: UInt64(saltSize + kCCBlockSizeAES128))
            let filenameAndTypeLen: Int = try file.read(upToCount: 1)!.withUnsafeBytes({ $0.pointee })
            
            try file.seek(toOffset: UInt64(ivEnd + 1 + filenameAndTypeLen))
            let thumbLen: Int = try file.read(upToCount: 1)!.withUnsafeBytes({ $0.pointee })
            
            try file.seek(toOffset: UInt64(ivEnd + 1 + filenameAndTypeLen + 1))
            let thumbData = try file.read(upToCount: thumbLen)!
            
            file.closeFile()
            
            blurHash = String(decoding: thumbData, as: UTF8.self)
            
            NSLog("extractThumbnail - \(fileURL.lastPathComponent) - blurHash extracted \(blurHash)" )
        } catch {NSLog("extractThumbnail - \(fileURL.lastPathComponent) - file ops error \(error)"); return nil}
        

        let im = UIImage.init(blurHash: blurHash, size: CGSize(width: 32, height: 32))

        if(im == nil) {NSLog("extractThumbnail - \(fileURL.lastPathComponent) - image creation failed \(fileURL)  \(blurHash)"); return nil}
        
        return im
    } else { NSLog("extractThumbnail - \(fileURL.lastPathComponent) - iOS version failure"); return nil}
}

func createThumbnail(_ fileURL: URL, completion: @escaping (String) -> Void) {
    if #available(iOS 13.0, *) {
        let previewGenerator = QLThumbnailGenerator()
        let thumbnailSize = CGSize(width: 50, height: 50)
        let scale = CGFloat(1)
        
        let request = QLThumbnailGenerator.Request(fileAt: fileURL, size: thumbnailSize, scale: scale, representationTypes: .thumbnail)
        
        previewGenerator.generateBestRepresentation(for: request) { (thumbnail, error) in

            if let error = error {
                print(error.localizedDescription)
            } else if let thumb = thumbnail {
                let blurhash = thumb.uiImage.blurHash(numberOfComponents: (4, 4))!
                
                completion(blurhash)
            }
        }
        
    }
}
