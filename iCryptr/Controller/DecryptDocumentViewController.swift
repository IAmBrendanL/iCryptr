//
//  DocumentViewController.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 2/4/18.
//  Copyright © 2018 Brendan Lindsey. All rights reserved.
//

import UIKit

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
        getPin {
            verifyIdentity(ReasonForAuthenticating: "Authorize use of default password") {
                guard let passwd = getPasswordFromKeychain(forAccount: ".password") else { return }
                self.decryptFileWithProgress(passwd)
            }
        }
    }
    

    // MARK: Class Methods
    func decryptFileWithProgress(_ passwd: String)  {
        // Encrypt the file and display UIActivityIndicatorView
        guard let fileURL = self.document?.fileURL else { return }
        self.decryptStackView.isHidden = false
        self.doneButton.isHidden = true
        DispatchQueue.global(qos: .background).async {
            let result = decryptFile(fileURL, passwd)
            DispatchQueue.main.async {
                self.decryptStackView.isHidden = true
                self.doneButton.isHidden = false
                messageAlert(messageTitle: result ? "Success": "Error", messageContent: "", parent: self)
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
    
    
    // MARK IBOutlets
    @IBOutlet weak var documentNameLabel: UILabel!
    @IBOutlet weak var decryptStackView: UIStackView!
    @IBOutlet weak var doneButton: UIButton!
    
    
    //Mark Class Variables
    var document: UIDocument?
}
