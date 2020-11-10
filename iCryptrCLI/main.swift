//
//  main.swift
//  iCryptrCLI
//
//  Created by Reuben Eggar on 10/11/2020.
//  Copyright © 2020 Reuben. All rights reserved.
//

import Foundation

let arguments = Array(CommandLine.arguments[1...])
var stderr = StandardErrorOutputStream()

if(arguments.count == 0) {print("umm where's the key?", to: &stderr); exit(1)}

let key = arguments[0]
let files = Array(arguments[1...])

if(files.count == 0) {print("can't decrypt thin air mate", to: &stderr); exit(1)}

func decrypt(_ path: String){
    let url = URL(fileURLWithPath: path)
    let (fileData, fileName) = decryptFile(url, key) ?? (nil, nil)
    
    if(fileData == nil) {print("decryption failure", url); return}
    
    let outfile = url.deletingLastPathComponent().appendingPathComponent(fileName!)
    print(outfile)
    
    do {
        try fileData!.write(to: outfile, options: .atomic)
        print("written", outfile)
    } catch {
        print("file write error")
    }
}

for file in files {
    decrypt(file)
}



final class StandardErrorOutputStream: TextOutputStream {
    func write(_ string: String) {
        FileHandle.standardError.write(Data(string.utf8))
    }
}
