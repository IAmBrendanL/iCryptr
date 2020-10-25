//
//  DocumentViewController.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 2/4/18.
//  Copyright © 2018 Brendan Lindsey. All rights reserved.
//

import UIKit
import MobileCoreServices
import ImageScrollView

class EncryptDocumentViewController: UIViewController {
    
    // MARK IB Actions for encryption
    @IBAction func getPasswordAndFileName() {
        // Set up alert controler to get password and new filename
        let alert = UIAlertController(title: "Enter Password & New File Name", message: "", preferredStyle: .alert)
        // encrypt file on save
        let alertSaveAction = UIAlertAction(title: "Submit", style: .default) { action in
            guard let passwordField = alert.textFields?[0], let password = passwordField.text else { return }
            guard let nameField = alert.textFields?[1], let newName = nameField.text else { return }
            self.encryptFileWithProgress(password, newName)
        }
        // set up cancel action
        let alertCancelAction = UIAlertAction(title: "Cancel", style: .default)
 
        // build alert from parts
        alert.addTextField { passwordField in
            passwordField.placeholder = "Password"
            passwordField.clearButtonMode = .whileEditing
            passwordField.isSecureTextEntry = true
            passwordField.autocapitalizationType = .none
            passwordField.autocorrectionType = .no
        }
        alert.addTextField{ nameField in
            nameField.placeholder = "The name for the encrypted file"
            nameField.clearButtonMode = .whileEditing
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
            // Set up alert controler to get password and new filename
//                let alert = UIAlertController(title: "Enter New File Name", message: nil, preferredStyle: .alert)
//                // encrypt file on save
//                let alertSaveAction = UIAlertAction(title: "Submit", style: .default) { action in
                guard let password = getPasswordFromKeychain(forAccount: ".password") else { return }
//                    guard let nameField = alert.textFields?[0], let newName = nameField.text else { return }
//                    print(newName)
            self.encryptFileWithProgress(password, self.document?.fileURL.lastPathComponent ?? "UNKNOWN NAME")
//                }
//                // set up cancel action
//                let alertCancelAction = UIAlertAction(title: "Cancel", style: .default)
//
//                // build alert from parts
//                alert.addTextField{ nameField in
//                    nameField.placeholder = "The name for the encrypted file"
//                    nameField.clearButtonMode = .whileEditing
//                }
//                alert.addAction(alertCancelAction)
//                alert.addAction(alertSaveAction)
//                alert.preferredAction = alertSaveAction
//
//                // present alert
//                self.present(alert, animated: true)
        }
    }
    
    
    
    // MARK: Class Methods
    func encryptFileWithProgress(_ passwd: String, _ newName: String)  {
        // Encrypt the file and display UIActivityIndicatorView
        guard let fileURL = self.document?.fileURL else { return }
        self.encryptStackView.isHidden = false
        DispatchQueue.global(qos: .background).async {
            let result = encryptFile(fileURL, passwd, newName)

            let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let temporaryDir = ProcessInfo().globallyUniqueString

            let tempFileDirURL = temporaryDirectoryURL.appendingPathComponent(temporaryDir)
            let tempFileURL = tempFileDirURL.appendingPathComponent(result!.fileName)
            
            do {
              try FileManager.default.createDirectory(at: tempFileDirURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("temp dir cr failed")
                return
            }
            
            print(tempFileURL)
            
            do {
                try result!.fileData.write(to: tempFileURL, options: .atomic)
                print("Written temp file")
            } catch {
                print("error")
                return
            }
            
            
            DispatchQueue.main.async {
                self.encryptStackView.isHidden = true
                let activityViewController = UIActivityViewController(activityItems: [tempFileURL], applicationActivities: nil)
                 
                
                activityViewController.completionWithItemsHandler = { activity, success, items, error in
                    if(success){
                        
                        do {
                            try FileManager.default.removeItem(at: tempFileURL)
                            print("removed files")
                        } catch {
                            print("failed to remove temporary url with error: \(error)")
                        }
                        
                        self.dismissDocumentViewController()
                        
                    }
                }
                
                self.present(activityViewController, animated: true)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationBar.layer.zPosition = 1
        self.navigationBar.topItem!.title = self.document?.fileURL.lastPathComponent
        
        let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (self.document?.fileURL)!.pathExtension as CFString, nil)
        
        if(UTTypeConformsTo((uti?.takeRetainedValue())!, kUTTypeImage)){
            self.imageScrollView.setup()
            
            let data = NSData(contentsOf: (self.document?.fileURL)!)
            self.imageScrollView.display(image: UIImage(data: data! as Data)!)
        }
        
        self.documentNameLabel.text = self.document?.fileURL.lastPathComponent
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
    
    
    // MARK: IB Outlets
    @IBOutlet weak var documentNameLabel: UILabel!
    @IBOutlet var encryptStackView: UIStackView!
    @IBOutlet weak var imageScrollView: ImageScrollView!
    @IBOutlet weak var navigationBar: UINavigationBar!

    // MARK: Class Variables
    var document: UIDocument?

}
