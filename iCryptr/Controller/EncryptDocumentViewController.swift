//
//  DocumentViewController.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 2/4/18.
//  Copyright © 2018 Brendan Lindsey. All rights reserved.
//

import UIKit

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
        getPin {
            verifyIdentity(ReasonForAuthenticating: "Authorize use of default password") {
                // Set up alert controler to get password and new filename
                let alert = UIAlertController(title: "Enter New File Name", message: nil, preferredStyle: .alert)
                // encrypt file on save
                let alertSaveAction = UIAlertAction(title: "Submit", style: .default) { action in
                    guard let password = getPasswordFromKeychain(forAccount: ".password") else { return }
                    guard let nameField = alert.textFields?[0], let newName = nameField.text else { return }
                    print(newName)
                    self.encryptFileWithProgress(password, newName)
                }
                // set up cancel action
                let alertCancelAction = UIAlertAction(title: "Cancel", style: .default)
                
                // build alert from parts
                alert.addTextField{ nameField in
                    nameField.placeholder = "The name for the encrypted file"
                    nameField.clearButtonMode = .whileEditing
                }
                alert.addAction(alertCancelAction)
                alert.addAction(alertSaveAction)
                alert.preferredAction = alertSaveAction
                
                // present alert
                self.present(alert, animated: true)
            }
        }
    }
    
    
    
    // MARK: Class Methods
    func encryptFileWithProgress(_ passwd: String, _ newName: String)  {
        // Encrypt the file and display UIActivityIndicatorView
        guard let fileURL = self.document?.fileURL else { return }
        self.encryptStackView.isHidden = false
        DispatchQueue.global(qos: .background).async {
            let _ = encryptFile(fileURL, passwd, newName)
            DispatchQueue.main.async {
                self.encryptStackView.isHidden = true
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Access the document
        document?.open(completionHandler: { (success) in
            if success {
                // Display the content of the document, e.g.:
                self.documentNameLabel.text = self.document?.fileURL.lastPathComponent
            } else {
                // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
            }
        })
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

    // MARK: Class Variables
    var document: UIDocument?

}
