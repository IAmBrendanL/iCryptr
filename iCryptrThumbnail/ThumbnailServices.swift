//
//  EncryptionServices.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 2/11/18.
//  Copyright © 2018 Brendan Lindsey. All rights reserved.
//

import Foundation

import QuickLookThumbnailing

let saltSize = 64

let kCCBlockSizeAES128  = 16

/**
 Takes in a packed Encrypted File and unpacks it
 */
fileprivate func unpackEncryptedFile( _ encryptedData: Data) -> (salt: Data, iv: Data, filenameAndType: Data, thumb: Data, cipherData: Data)? {
    // need to think about what I want out of this... do I want it to return multiple objects or just parts that are
    // requested via another param and switch statement?
    // helper constant
    
    let salt = encryptedData.subdata(in: 0..<saltSize)
    let ivEnd = saltSize + kCCBlockSizeAES128
    let iv = encryptedData.subdata(in: saltSize..<ivEnd)
    
    let filenameAndTypeLen = encryptedData.subdata(in: ivEnd..<ivEnd+1).withUnsafeBytes { dataPtr -> Int in
        return dataPtr.pointee
    }
    let filenameAndType = encryptedData.subdata(in: ivEnd+1..<ivEnd+1+filenameAndTypeLen)
    
    let thumbLen = encryptedData.subdata(in: ivEnd+1+filenameAndTypeLen..<ivEnd+1+filenameAndTypeLen+1).withUnsafeBytes { dataPtr -> Int in
        return dataPtr.pointee
    }
    let thumb = encryptedData.subdata(in: ivEnd+1+filenameAndTypeLen+1..<ivEnd+1+filenameAndTypeLen+1+thumbLen)
    
    
    let cipherData = encryptedData.subdata(in: ivEnd+1+filenameAndTypeLen+1+thumbLen..<encryptedData.count)
    return (salt, iv, filenameAndType, thumb, cipherData)
}



func extractThumbnail(_ encryptedData: Data) -> String? {
    let unpacked = unpackEncryptedFile(encryptedData)
    
    if(unpacked?.thumb == nil) {return nil}
    return String(decoding: unpacked!.thumb, as: UTF8.self)
    // (salt: Data, iv: Data, filenameAndType: Data, thumb: Data, cipherData: Data)?
}
