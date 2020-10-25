//
//  EncryptionServices.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 2/11/18.
//  Copyright © 2018 Brendan Lindsey. All rights reserved.
//

import Foundation

let saltSize = 64


/**
 Derieves an AES256 key from given password, salt, and rounds using Apple's open source CommonCrypto library
 - parameters:
    - passwd: The password from the user.
    - salt: A salt generated or from a file to decrypt.
    - rounds: A UInt32 signifying the number of rounds to run the key derivation algorithm. Use getKeyGenerationRounds
              to generate or get it from a file to decrypt.
 */
fileprivate func generateKeyFromPassword(_ passwd: String, _ salt: Data, _ rounds: UInt32) -> Data? {
    var key = Data(count:kCCKeySizeAES256)
    guard let saltString = String(data: salt, encoding: .ascii) else {return nil}
    let success = key.withUnsafeMutableBytes { keyPtr in
        return CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), passwd,
                                    strlen(passwd), saltString, strlen(saltString),
                                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                                    rounds, keyPtr, kCCKeySizeAES256)
    }
    // if key derivation was successful
    if success == kCCSuccess {
        // return key
        return key
    }
    // if key derivation was not successful
    return nil
}


/**
 Get the rounds to run key derivation for current platform as an unsigned 32 bit integer.
 - parameters:
    - passwd: The password from the user.
    - salt: A salt generated or from a file to decrypt.
 */
fileprivate func getKeyGenerationRounds(_ passwd: String, _ salt: Data) -> UInt32 {
    guard let saltString = String(data: salt, encoding: .ascii) else {return 9999}
    return CCCalibratePBKDF(CCPBKDFAlgorithm(kCCPBKDF2), strlen(passwd), strlen(saltString),
                            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), kCCKeySizeAES256, 500)
}


/**
 Generates an 8 byte cryptographically secure random salt.
 */
fileprivate func generateSaltForKeyGeneration() -> Data? {
    let uint8Pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: saltSize)
    let result = SecRandomCopyBytes(kSecRandomDefault, saltSize, uint8Pointer)
    
    // if successful
    if result == errSecSuccess {
        let salt = Data(bytes:uint8Pointer, count: saltSize)
        // free memory amd return
        uint8Pointer.deinitialize(count: saltSize)
        uint8Pointer.deallocate()
        return salt
    }
    // if error
    return nil
}


/**
 Generates a cryptograpically secure random intitialization vector
 */
fileprivate func generateIVForFileEncryption() -> Data? {
    let uint8Pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: kCCBlockSizeAES128)
    
    let result = SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, uint8Pointer)
    
    // if successful
    if result == errSecSuccess {
        let iv = Data(bytes:uint8Pointer, count: kCCBlockSizeAES128)
        // free memory amd return
        uint8Pointer.deinitialize(count: kCCBlockSizeAES128)
        uint8Pointer.deallocate()
        return iv
    }
    // if error
    return nil
}


/**
 Swift wrapper around CCcrypt for encryption of data
 - Parameters:
    - key: A Data object holding an AES256 key
    - iv: A Data object holding an initialization vector
    - plainData: A Data object holding the "PlßßainText" to encrypt
 - Returns:
    - A Data object with the encrypted data if successful
    - nil if uncessful
 */
fileprivate func encryptDataWith(_ key: Data, _ iv: Data, _ plainData: Data) -> Data? {
    // holds number needed
    var numEncrypted = 0
    // set cipherData size and store counts for modification
    var cipherData = Data(repeating: 0, count: plainData.count + iv.count)
    let cipherDataCount = cipherData.count
    let plainDataCount = plainData.count
    // start encrypton and return status
    let status = key.withUnsafeBytes { keyPtr in
        iv.withUnsafeBytes { ivPtr in
            plainData.withUnsafeBytes { plainDataPtr in
                cipherData.withUnsafeMutableBytes { cipherDataPtr in
                    return  CCCrypt(CCOperation(kCCEncrypt), CCAlgorithm(kCCAlgorithmAES128),
                                    CCOptions(kCCOptionPKCS7Padding), keyPtr, kCCKeySizeAES256, ivPtr,
                                    plainDataPtr, plainDataCount, cipherDataPtr, cipherDataCount,
                                    &numEncrypted)
                }
            }
        }
    }
    //adjust bytes to real length
    cipherData.count = numEncrypted
    // return result
    return kCCSuccess == status ? cipherData : nil
}


/**
Swift wrapper around CCcrypt for decryption of data
 - Parameters:
    - key: A Data object holding an AES256 key
    - cipherData: A Data object holding the "CipherText" to decrypted
 - Returns:
    - A Data object with the decrypted data if successful
    - nil if uncessful
 */
fileprivate func decryptDataWith(_ key: Data, _ iv: Data, _ cipherData: Data) -> Data? {
    // holds number needed
    var numDecrypted = 0
    // set cipherData size and store count for modification
    var plainData = Data(count: cipherData.count + kCCBlockSizeAES128)
    let plainDataCount = plainData.count
    // start encrypton and return status
    let status = key.withUnsafeBytes { keyPtr in
        iv.withUnsafeBytes { ivPtr in
            cipherData.withUnsafeBytes { cipherDataPtr in
                plainData.withUnsafeMutableBytes { plainDataPtr in
                    return  CCCrypt(CCOperation(kCCDecrypt), CCAlgorithm(kCCAlgorithmAES128),
                                    CCOptions(kCCOptionPKCS7Padding), keyPtr, kCCKeySizeAES256, ivPtr,
                                    cipherDataPtr, cipherData.count, plainDataPtr, plainDataCount,
                                    &numDecrypted)
                }
            }
        }
    }
    //adjust bytes to real length
    plainData.count = numDecrypted
    // return result
    return kCCSuccess == status ? plainData : nil
}


/**
 Concatanates the binary data (salt, iv, and encrypted data) so that
 the file written out contains all of the peices needed to decrypt it
 - Parameters:
    - salt: A Data object holding the salt string in bytes
    - iv: A Data object holding the intialization vector bytes
    - cipherFilenameAndType: A Data object holding the encrypted file name and type
    - cipherData: A Data object holding the encrypted file data
 - Returns:
    - nil: If name len is too long or the binary data is not correctly created
    - Data: the packed file if creation works
 */
fileprivate func packEncryptedFile(_ salt: Data, _ iv: Data, _ cipherFilenameAndType: Data, _ cipherData: Data) -> Data? {
    let lenData = Data(repeating: UInt8(cipherFilenameAndType.count), count: 1)
    // if nameLen did not fit in one byte
    if lenData.count != 1 { return nil }
    var encryptedData = Data()
    
    encryptedData.append(salt)
    encryptedData.append(iv)
    encryptedData.append(lenData)
    encryptedData.append(cipherFilenameAndType)
    encryptedData.append(cipherData)
    
    // verify that the data length is correct before returning
    if encryptedData.count != salt.count + iv.count + lenData.count + cipherFilenameAndType.count + cipherData.count {
        return nil
    }
    return encryptedData
}



/**
 Takes in a packed Encrypted File and unpacks it
 */
fileprivate func unpackEncryptedFile( _ encryptedData: Data) -> (salt: Data, iv: Data, filenameAndType: Data, cipherData: Data)? {
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
    let cipherData = encryptedData.subdata(in: ivEnd+1+filenameAndTypeLen..<encryptedData.count)
    return (salt, iv,filenameAndType, cipherData)
}


/**
 Try to write out a file to a unique file (avoid name collisons)
 Public as it may be useful elsewhere
 - Parameters:
     - dirURL: The url to the directory to write the file
     - fileName: The file name for the file to be written to
     - fileData: The file data
 */
func nondestructiveWrite(_ dirURL: URL, _ fileName: String, _ fileExtention: String, _ fileData: Data) -> Bool {
    let fManager = FileManager.default
    var fileURL =  dirURL.appendingPathComponent(fileName+"."+fileExtention)
    for i in 1...10000 {
        // check if file exists and either try to write the file or update the filename)
        if !fManager.fileExists(atPath: fileURL.path) {
            do {
                try fileData.write(to: fileURL)
                return true
            } catch {
                return false
            }
        } else {
             fileURL = dirURL.appendingPathComponent("\(fileName)-\(String(i)).\(fileExtention)")
        }
    }
    // if here then in 10000 iterations no filename was found to be available
    return false
}


/**
 Encrypts a file and writes out the encrypted data
 - Parameters:
     - fileURL: A URL with the file location
     - passwd: The password to encrypt with
     - encryptedFileName: The file name to write the encrypted file to
 */
func encryptFile(_ fileURL: URL, _ passwd: String, _ encryptedFileName: String) -> Bool {
    
    var result = false
    do {
        // get parts for encryption
        guard let fileNameData = fileURL.lastPathComponent.data(using: .utf8) else { return false }
        let fileData = try Data(contentsOf: fileURL)
        guard let salt = generateSaltForKeyGeneration() else { return false }
        guard let key = generateKeyFromPassword(passwd, salt, 750000) else { return false }
        guard let iv = generateIVForFileEncryption() else { return false }
        // do encryption
        guard let encryptedFileNameData = encryptDataWith(key, iv, fileNameData) else { return false }
        guard let encryptedFile = encryptDataWith(key, iv, fileData) else { return false }
        // pack bytes and write file out
        guard let packedEncryptedFile = packEncryptedFile(salt, iv, encryptedFileNameData, encryptedFile) else { return false }
        result = nondestructiveWrite(fileURL.deletingLastPathComponent(), encryptedFileName, "iCryptr", packedEncryptedFile)
        
    } catch {
        return false
    }
    // return
    return result
}


/**
 Decrypts a file and writes out the decrypted data
 - Parameters:
     - fileURL: A URL with the file location
     - passwd: The password to decrypt with
 */
func decryptFile(_ fileURL: URL, _ passwd: String) -> (Data, String)? {
    do {
        // get parts for decryption
        let fileData = try Data(contentsOf: fileURL)
        guard let unpackedFile = unpackEncryptedFile(fileData) else { return nil }
        guard let key = generateKeyFromPassword(passwd, unpackedFile.salt, 750000) else { return nil }
        // do decryption
        guard let decryptedFileNameData = decryptDataWith(key, unpackedFile.iv, unpackedFile.filenameAndType) else { return nil }
        guard let decryptedFileName = String(data: decryptedFileNameData, encoding: .utf8) else { return nil }
        guard let decryptedData = decryptDataWith(key, unpackedFile.iv, unpackedFile.cipherData) else { return nil }
        // write file
        /* result = nondestructiveWrite(fileURL.deletingLastPathComponent(),
                                     (decryptedFileName as NSString).deletingPathExtension,
                                     (decryptedFileName as NSString).pathExtension, decryptedData)
        */
        return (decryptedData, decryptedFileName)
    } catch {
        return nil
    }
}
