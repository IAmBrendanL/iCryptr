
//
//  EncryptionServices.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 2/11/18.
//  Copyright © 2018 Brendan Lindsey. All rights reserved.
//

import Foundation

import QuickLookThumbnailing

func extractThumbnail(_ encryptedData: Data) -> String? {
    let unpacked = unpackEncryptedFile(encryptedData)
    
    if(unpacked?.thumb == nil) {return nil}
    return String(decoding: unpacked!.thumb, as: UTF8.self)
    // (salt: Data, iv: Data, filenameAndType: Data, thumb: Data, cipherData: Data)?
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
                print(blurhash) // image available
                
                completion(blurhash)
            }
        }
        
    }
}
