//
//  EncryptionServices.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 2/11/18.
//  Copyright © 2018 Brendan Lindsey. All rights reserved.
//

import Foundation

/**
 This function uses Apple's open source CommonCrypto library to derive an AES256 key from given password, salt, and
 rounds.
 - parameters:
    - passwd: The password from the user.
    - salt: A salt generated or from a file to decrypt.
    - rounds: A UInt32 signifying the number of rounds to run the key derivation algorithm. Use getKeyGenerationRounds
              to generate or get it from a file to decrypt.
 */
func generateKeyFromPassword(_ passwd: String, _ salt: String, _ rounds: UInt32) -> String {
    // UnsafeMutablePointer initialization used from Apple's UnsafeMutablePointer documentation.
    // See https://developer.apple.com/documentation/swift/unsafemutablepointer
    let uint8Pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: 8)
    uint8Pointer.initialize(from: [1, 1, 1, 1, 1, 1, 1, 1, 0], count: 8)
    let length = 8
    // derive key
    let _ = CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), passwd, strlen(passwd), salt, strlen(salt),
                                 CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), rounds, uint8Pointer, length)
    // build result
    var derivedKey = ""
    for i in 0...length-1 {
        derivedKey += String(uint8Pointer[i])
    }
    // free memory
    uint8Pointer.deinitialize(count: 8)
    uint8Pointer.deallocate(capacity: 8)
    // return key
    return derivedKey
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
    uint8Pointer.initialize(from: [1, 1, 1, 1, 1, 1, 1, 1, 0], count: 8)

    let result = SecRandomCopyBytes(kSecRandomDefault, 8, uint8Pointer)
    
    if result != errSecSuccess {
        return nil
    }
    
    var salt = ""
    for i in 0...7 {
        salt += String(uint8Pointer[i])
    }
    
    return salt
}

