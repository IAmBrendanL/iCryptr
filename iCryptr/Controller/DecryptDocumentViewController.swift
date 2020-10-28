//
//  DocumentViewController.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 2/4/18.
//  Copyright © 2018 Brendan Lindsey. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

import ImageScrollView

class DecryptDocumentViewController: UIViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationBar.layer.zPosition = 1
        
        
        if(self.decryptedData == nil) {
            self.resultImageScrollView.setup()
            
            self.navigationBar.topItem!.title = self.document?.fileURL.lastPathComponent
            self.shareButton.isEnabled = false
            
            
            if let image = extractThumbnail(self.document!.fileURL){
                self.resultImageScrollView.display(image: image)
                self.unlockButton.isEnabled = true
            }
            self.decryptWithDefaultPasswordFlow()
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isBeingDismissed && (self.tempFileURL != nil) {
            do {
                try FileManager.default.removeItem(at: self.tempFileURL!)
                print("removed files")
            } catch {
                print("failed to remove temporary url with error: \(error)")
            }
        }
        
    }
    
    @IBAction func dismissDocumentViewController() {
        dismiss(animated: true) {
            self.document?.close(completionHandler: nil)
        }
    }
    
    // MARK: UIActions for decryption
    @IBAction func decryptWithSpecificPasswordFlow() {
        // Set up alert controller to get password
        let alert = UIAlertController(title: "Enter Password", message: "", preferredStyle: .alert)
        // decrypt file on save
        let alertSaveAction = UIAlertAction(title: "Submit", style: .default) { action in
            guard let passwordField = alert.textFields?[0], let password = passwordField.text else { return }
            self.decryptCommonFlow(password){_ in}
        }
        let alertCancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        // build alert from parts
        alert.addTextField { passwordField in
            passwordField.placeholder = "Password"
            passwordField.clearButtonMode = .whileEditing
            passwordField.isSecureTextEntry = true
            passwordField.autocapitalizationType = .none
            passwordField.autocorrectionType = .no
        }
        alert.addAction(alertCancelAction)
        alert.addAction(alertSaveAction)
        alert.preferredAction = alertSaveAction
        
        // present alert
        present(alert, animated: true)
    }
   
    @IBAction func decryptWithDefaultPasswordFlow() {
        verifyIdentity(ReasonForAuthenticating: "Authorize use of default password") {authenticated in
            if(authenticated) {
                guard let passwd = getPasswordFromKeychain(forAccount: ".password") else { return }
                self.decryptCommonFlow(passwd) {success in
                    if(!success) {
                        self.decryptWithSpecificPasswordFlow()
                    }
                }
            } else {
                self.activityIndicator.stopAnimating()
            }
        }
    }
    

    // MARK: Class Methods
    func decryptCommonFlow(_ passwd: String, completion: @escaping (Bool) -> Void) -> Void  {
        self.activityIndicator.startAnimating()
        // Dencrypt the file and display UIActivityIndicatorView
        guard let fileURL = self.document?.fileURL else { return completion(false)}
        DispatchQueue.global(qos: .background).async {
            let (fileData, fileName) = decryptFile(fileURL, passwd) ?? (nil, nil)
            
            
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                
                if(fileData != nil) {
                    completion(true)
                    
                    self.decryptedData = fileData
                    
                    self.shareButton.isEnabled = true
                    self.shareButton.action = #selector(self.share)
                    self.shareButton.target = self
                    
                    self.navigationBar.topItem!.title = fileName!
                    self.unlockButton.isEnabled = false
                    
                    let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                    let temporaryDir = ProcessInfo().globallyUniqueString

                    let tempFileDirURL = temporaryDirectoryURL.appendingPathComponent(temporaryDir)
                    self.tempFileURL = tempFileDirURL.appendingPathComponent(fileName!)
                    
                    do {
                      try FileManager.default.createDirectory(at: tempFileDirURL, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        print("temp dir cr failed")
                        return completion(false)
                    }
                    
                    print(self.tempFileURL!)
                    
                    do {
                        try fileData!.write(to: self.tempFileURL!, options: .atomic)
                        print("Written temp file")
                    } catch {
                        print("error")
                        return completion(false)
                    }
                    
                    
                    
                    if let image = UIImage(data: fileData!){
                        self.resultImageScrollView.display(image: image)
                    } else {
                        let avAsset = AVURLAsset(url: self.tempFileURL!)

                        if(avAsset.isPlayable) {
                            let player = AVPlayer(url: self.tempFileURL!)
                            let playerViewController = AVPlayerViewController()
                            playerViewController.player = player
                            
                            self.present(playerViewController, animated: true) {
                                playerViewController.player!.play()
                            }
                        }
                    }
                } else {
                    print("Decrypt Failed")
                    
                    completion(false)
                }
            }
        }
    }
    
    @objc private func share() {
        let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [self.tempFileURL!], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    // MARK IBOutlets
    @IBOutlet weak var resultImageScrollView: ImageScrollView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var unlockButton: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    enum DecryptedType {
        case image
        case video
    }
    
    var decryptedData: Data? = nil
    
    var tempFileURL: URL? = nil
    
    //Mark Class Variables
    var document: UIDocument?
}
