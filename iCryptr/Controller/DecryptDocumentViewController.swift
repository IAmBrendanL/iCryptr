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

import BlurHash

class DecryptDocumentViewController: UIViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationBar.layer.zPosition = 1
        
        
        if(self.decryptedData == nil) {
            self.resultImageScrollView.setup()
            
            self.navigationBar.topItem!.title = self.document?.fileURL.lastPathComponent
            self.documentNameLabel.text = self.document?.fileURL.lastPathComponent
            self.shareButton.isEnabled = false
            
            var data: Data? = nil
            
            do {
                data = try Data(contentsOf: self.document!.fileURL as URL)
            } catch {
                print("Unable to load data: \(error)")
                
                return
            }
            
            if(self.decryptedType == nil) {
                if let image = UIImage.init(blurHash: extractThumbnail(data!)!, size: CGSize(width: 32, height: 32)){
                    self.resultImageScrollView.display(image: image)
                }
                self.decryptWithDefaultPasswordFlow()
            }
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
            self.decryptCommonFlow(password)
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
        verifyIdentity(ReasonForAuthenticating: "Authorize use of default password") {
            guard let passwd = getPasswordFromKeychain(forAccount: ".password") else { return }
            self.decryptCommonFlow(passwd)
        }
    }
    

    // MARK: Class Methods
    func decryptCommonFlow(_ passwd: String)  {
        // Dencrypt the file and display UIActivityIndicatorView
        guard let fileURL = self.document?.fileURL else { return }
        self.decryptStackView.isHidden = false
        self.doneButton.isHidden = true
        DispatchQueue.global(qos: .background).async {
            let (fileData, fileName) = decryptFile(fileURL, passwd) ?? (nil, nil)
            self.decryptedData = fileData
            
            
            DispatchQueue.main.async {
                if(fileData != nil) {
                    self.shareButton.isEnabled = true
                    self.shareButton.action = #selector(self.share)
                    self.shareButton.target = self
                    
                    self.documentNameLabel.text = fileName!
                    self.navigationBar.topItem!.title = fileName!
                    print(fileName!)
                    
                    let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                    let temporaryDir = ProcessInfo().globallyUniqueString

                    let tempFileDirURL = temporaryDirectoryURL.appendingPathComponent(temporaryDir)
                    self.tempFileURL = tempFileDirURL.appendingPathComponent(fileName!)
                    
                    do {
                      try FileManager.default.createDirectory(at: tempFileDirURL, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        print("temp dir cr failed")
                        return
                    }
                    
                    print(self.tempFileURL!)
                    
                    do {
                        try fileData!.write(to: self.tempFileURL!, options: .atomic)
                        print("Written temp file")
                    } catch {
                        print("error")
                        return
                    }
                    
                    
                    if let image = UIImage(data: fileData!){
                        self.resultImageScrollView.display(image: image)
                        self.wholeStackView.isHidden = true
                        self.decryptStackView.isHidden = true
                        self.doneButton.isHidden = false
                        self.decryptedType = .image

                    } else {
                        
                        
                        let avAsset = AVURLAsset(url: self.tempFileURL!)

                        if(avAsset.isPlayable) {
                            let player = AVPlayer(url: self.tempFileURL!)
                            self.decryptedType = .video
                            let playerViewController = AVPlayerViewController()
                            playerViewController.player = player
                            self.present(playerViewController, animated: true) {
                                playerViewController.player!.play()
                            }
                        }
                        
                        
                    }
                }
            }
        }
    }
    
    @objc private func share() {
        let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [self.tempFileURL!], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView=self.view
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    // MARK IBOutlets
    @IBOutlet weak var wholeStackView: UIStackView!
    
    @IBOutlet weak var documentNameLabel: UILabel!
    @IBOutlet weak var decryptStackView: UIStackView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var resultImageScrollView: ImageScrollView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    enum DecryptedType {
        case image
        case video
    }
    
    var decryptedType: DecryptedType? = nil
    var decryptedData: Data? = nil
    
    var tempFileURL: URL? = nil
    
    //Mark Class Variables
    var document: UIDocument?
}
