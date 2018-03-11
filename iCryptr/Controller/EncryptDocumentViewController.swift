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

        alert.addAction(alertSaveAction)
        alert.addAction(alertCancelAction)
        alert.preferredAction = alertSaveAction
        
        // present alert
        present(alert, animated: true)
    }
    
    @IBAction func dismissDocumentViewController() {
        dismiss(animated: true) {
            self.document?.close(completionHandler: nil)
        }
    }
    
    // MARK: Class Methods
    func encryptFileWithProgress(_ passwd: String, _ newName: String)  {
        // Encrypt the file and display UIActivityIndicatorView
        guard let fileURL = self.document?.fileURL else { return }
        self.encryptStackView.isHidden = false
        DispatchQueue.global(qos: .background).async {
            encryptFile(fileURL, passwd, newName)
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
    
    
    // MARK: IB Outlets
    @IBOutlet weak var documentNameLabel: UILabel!
    @IBOutlet var encryptStackView: UIStackView!

    // MARK: Class Variables
    var document: UIDocument?

}
