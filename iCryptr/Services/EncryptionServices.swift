//
//  EncryptionServices.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 2/11/18.
//  Copyright © 2018 Brendan Lindsey. All rights reserved.
//

import Foundation

/**
 Derieves an AES256 key from given password, salt, and rounds using Apple's open source CommonCrypto library
 - parameters:
    - passwd: The password from the user.
    - salt: A salt generated or from a file to decrypt.
    - rounds: A UInt32 signifying the number of rounds to run the key derivation algorithm. Use getKeyGenerationRounds
              to generate or get it from a file to decrypt.
 */
func generateKeyFromPassword(_ passwd: String, _ salt: String, _ rounds: UInt32) -> Data? {
    var key = Data(count:kCCKeySizeAES256)
    let success = key.withUnsafeMutableBytes { keyPtr in
        return CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), passwd,
                                    strlen(passwd), salt, strlen(salt),
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
func getKeyGenerationRounds(_ passwd: String, _ salt: String) -> UInt32 {
    return CCCalibratePBKDF(CCPBKDFAlgorithm(kCCPBKDF2), strlen(passwd), strlen(salt),
                            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), 8, 500)
}


/**
 Generates an 8 byte cryptographically secure random salt.
 */
func generateSaltForKeyGeneration() -> String? {
    let uint8Pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: 8)
    let result = SecRandomCopyBytes(kSecRandomDefault, 8, uint8Pointer)
    
    // if successful
    if result == errSecSuccess {
        // build salt
        var salt = ""
        for i in 0...7 {
            salt += String(uint8Pointer[i])
        }
        // free memory amd return
        uint8Pointer.deinitialize(count: 8)
        uint8Pointer.deallocate(capacity: 8)
        return salt
    }
    // if error
    return nil
}


/**
 Generates a cryptograpically secure random intitialization vector
 */
func generateIVForFileEncryption() -> Data? {
    let uint8Pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: kCCBlockSizeAES128)
    
    let result = SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, uint8Pointer)
    
    // if successful
    if result == errSecSuccess {
        let iv = Data(bytes:uint8Pointer, count: kCCBlockSizeAES128)
        // free memory amd return
        uint8Pointer.deinitialize(count: 8)
        uint8Pointer.deallocate(capacity: 8)
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
    - plainData: A Data object holding the "PlainText" to encrypt
 - Returns:
    - A Data object with the encrypted data if successful
    - nil if uncessful
 */
func encryptFile(_ key: Data, _ iv: Data, _ plainData: Data) -> Data? {
    // holds number needed
    var numEncrypted = 0
    // set cipherData size
    var cipherData = Data(repeating: 0, count: plainData.count + iv.count)
    // start encrypton and return status
    let status = key.withUnsafeBytes { keyPtr in
        iv.withUnsafeBytes { ivPtr in
            plainData.withUnsafeBytes { plainDataPtr in
                cipherData.withUnsafeMutableBytes { cipherDataPtr in
                    return  CCCrypt(CCOperation(kCCEncrypt), CCAlgorithm(kCCAlgorithmAES128),
                                    CCOptions(kCCOptionPKCS7Padding), keyPtr, kCCKeySizeAES256, ivPtr,
                                    plainDataPtr, plainData.count, cipherDataPtr, cipherData.count,
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
func decryptFile(_ key: Data, _ iv: Data, _ cipherData: Data) -> Data? {
    // holds number needed
    var numDecrypted = 0
    // set cipherData size
    var plainData = Data(count: cipherData.count + kCCBlockSizeAES128)
    // start encrypton and return status
    let status = key.withUnsafeBytes { keyPtr in
        iv.withUnsafeBytes { ivPtr in
            cipherData.withUnsafeBytes { cipherDataPtr in
                plainData.withUnsafeMutableBytes { plainDataPtr in
                    return  CCCrypt(CCOperation(kCCDecrypt), CCAlgorithm(kCCAlgorithmAES128),
                                    CCOptions(kCCOptionPKCS7Padding), keyPtr, kCCKeySizeAES256, ivPtr,
                                    cipherDataPtr, cipherData.count, plainDataPtr, plainData.count,
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


