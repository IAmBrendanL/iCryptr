//
//  DocumentViewController.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 2/4/18.
//  Copyright © 2018 Brendan Lindsey. All rights reserved.
//

import UIKit

class EncryptDocumentViewController: UIViewController {
    
    //MARK: UIActions for encryption
    @IBAction func encryptFileWithSpecificPassword() {
        // Get file URL to encrypt
        let fileURL = self.document?.fileURL
        // Get password and document name to write out to via UIAlertController
        let alert = UIAlertController(title: "Enter Password & New File Name", message: "", preferredStyle: .alert)
        let alertSaveAction = UIAlertAction(title: "Submit", style: .default) { action in
            guard let passwordField = alert.textFields?[0], let password = passwordField.text else { return }
            guard let nameField = alert.textFields?[1], let newFileName = nameField.text else { return }
            // encrypt file
            // Status passing to user not yet handled!
            encryptFile(fileURL!, password, newFileName)
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
        alert.addTextField{ nameField in
            nameField.placeholder = "The name for the encrypted file"
            nameField.clearButtonMode = .whileEditing
        }
        alert.addAction(alertSaveAction)
        alert.addAction(alertCancelAction)
        alert.preferredAction = alertSaveAction
        
        // present alert
        present(alert, animated: true)
    }
    
    
    
    @IBOutlet weak var documentNameLabel: UILabel!
    
    var document: UIDocument?
    
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
    
    @IBAction func dismissDocumentViewController() {
        dismiss(animated: true) {
            self.document?.close(completionHandler: nil)
        }
    }
}
