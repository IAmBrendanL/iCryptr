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
    
    // MARK: UIActions for decryption
    @IBAction func decryptFileWithSpecificPassword() {
        // Set up alert controller to get password
        let alert = UIAlertController(title: "Enter Password", message: "", preferredStyle: .alert)
        // decrypt file on save
        let alertSaveAction = UIAlertAction(title: "Submit", style: .default) { action in
            guard let passwordField = alert.textFields?[0], let password = passwordField.text else { return }
            self.decryptFileWithProgress(password)
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
   
    @IBAction func dismissDocumentViewController() {
        dismiss(animated: true) {
            self.document?.close(completionHandler: nil)
        }
    }

    @IBAction func useDefaultPassword() {
        verifyIdentity(ReasonForAuthenticating: "Authorize use of default password") {
            guard let passwd = getPasswordFromKeychain(forAccount: ".password") else { return }
            self.decryptFileWithProgress(passwd)
        }
    }
    

    // MARK: Class Methods
    func decryptFileWithProgress(_ passwd: String)  {
        // Dencrypt the file and display UIActivityIndicatorView
        guard let fileURL = self.document?.fileURL else { return }
        self.decryptStackView.isHidden = false
        self.doneButton.isHidden = true
        DispatchQueue.global(qos: .background).async {
            let (data, filename) = decryptFile(fileURL, passwd) ?? (nil, nil)
            self.decryptedData = data
            
            
            DispatchQueue.main.async {
                if(data != nil) {
                    self.shareButon.isEnabled = true
                    self.shareButon.action = #selector(self.share)
                    self.shareButon.target = self
                    
                    
                    let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                    let temporaryFilename = ProcessInfo().globallyUniqueString

                    self.tempFileURL = temporaryDirectoryURL.appendingPathComponent(temporaryFilename + filename!)
                    
                    print(self.tempFileURL!)
                    
                    do {
                        try data!.write(to: self.tempFileURL!, options: .atomic)
                        print("Written")
                    } catch {
                        print("error")
                        return
                    }
                    
                    if let image = UIImage(data: data!){
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationBar.layer.zPosition = 1
        self.navigationBar.topItem!.title = self.document?.fileURL.lastPathComponent
        
        if(self.decryptedData == nil) {
            self.shareButon.isEnabled = false
        }
        
    
        
        
        
        // Access the document
        document?.open(completionHandler: { (success) in
            if success {
                // Display the content of the document, e.g.:
                self.documentNameLabel.text = self.document?.fileURL.lastPathComponent
                self.resultImageScrollView.setup()
                
                if(self.decryptedType == nil) {
                    self.useDefaultPassword()
                }
            } else {
                // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
            }
        })
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
    
    
    // MARK: Private Methods
    private func getPin(_ completion: @escaping () -> Void) {
        // Set up alert controller to get password
        let alert = UIAlertController(title: "Enter Pin", message: nil, preferredStyle: .alert)
        // set default password on save
        let alertSaveAction = UIAlertAction(title: "Submit", style: .default) { action in
            guard let pinField = alert.textFields?[0], let pin = pinField.text else { return }
            if checkPin(pin) {
                completion()
            }
        }
        let alertCancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        // build alert from parts
        alert.addTextField { pinField in
            pinField.placeholder = "Password"
            pinField.clearButtonMode = .whileEditing
            pinField.isSecureTextEntry = true
            pinField.autocapitalizationType = .none
            pinField.autocorrectionType = .no
            pinField.keyboardType = .numberPad
        }
        alert.addAction(alertCancelAction)
        alert.addAction(alertSaveAction)
        alert.preferredAction = alertSaveAction
        
        // present alert
        self.present(alert, animated: true)
    }
    
    
    // MARK IBOutlets
    @IBOutlet weak var wholeStackView: UIStackView!
    
    @IBOutlet weak var documentNameLabel: UILabel!
    @IBOutlet weak var decryptStackView: UIStackView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var resultImageScrollView: ImageScrollView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var shareButon: UIBarButtonItem!
    
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
