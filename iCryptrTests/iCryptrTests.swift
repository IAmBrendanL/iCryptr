//
//  iCryptrTests.swift
//  iCryptrTests
//
//  Created by Brendan Lindsey on 2/4/18.
//  Copyright © 2018 Brendan Lindsey. All rights reserved.
//

import XCTest
@testable import iCryptr

class iCryptrTests: XCTestCase {
    
    
    func testGenerateKeyFromPassword() {
        // Test that keys generated are unique and not nil
        let firstPairResult1 = generateKeyFromPassword("password23434b%3929057!@^&*(<.87=+¨ˆ∑´", "salt*$&*b19!@¥ø†√¨", 100000)
        let secondPairResult1 = generateKeyFromPassword("newpass48nn39dkj%394n__=38593*", "wq34", 100000)
        let firstPairResult2 = generateKeyFromPassword("password23434b%3929057!@^&*(<.87=+¨ˆ∑´", "salt*$&*b19!@¥ø†√¨", 100000)
        let secondPairResult2 = generateKeyFromPassword("newpass48nn39dkj%394n__=38593*", "wq34", 100000)
        
        //Assert
        XCTAssertNotNil(firstPairResult1)
        XCTAssertNotNil(secondPairResult1)
        XCTAssertNotNil(firstPairResult2)
        XCTAssertNotNil(secondPairResult2)
        XCTAssertTrue(firstPairResult1 == firstPairResult2,
                      "Keys generated with the same password, salt, and rounds are different")
        XCTAssertTrue(secondPairResult1 == secondPairResult2,
                      "Keys generated with the same password, salt, and rounds are different.")
        XCTAssertTrue(firstPairResult1 != secondPairResult1,
                       "Keys generated with different values directly after eachother are the same.")
    
    }
    
    func testSalts() {
        // Test that salts are unique and not returning errors
        var salts: Array<String?> = []
        for _ in 0...99 {
            salts.append(generateSaltForKeyGeneration())
        }
        for i in 0...salts.count-2 {
            let item = salts[i]
            XCTAssertNotNil(item, "Got nil at least once")
            for j in i+1...salts.count-1 {
                XCTAssertNotEqual(item, salts[j], String(format:"Salts are not unique for pair %i, %i", i, j))
            }
        }
    }

    func testIVs() {
        // Test that initialization vectors are unique and not returning errors
        var ivs: Array<Data?> = []
        for _ in 0...99 {
            ivs.append(generateIVForFileEncryption())
        }
        for i in 0...ivs.count-2 {
            let item = ivs[i]
            XCTAssertNotNil(item, "Got nil at least once")
            for j in i+1...ivs.count-1 {
                XCTAssertNotEqual(item, ivs[j], String(format:"IVs are not unique for pair %i, %i", i, j))
            }
        }
    }
    
    
}
