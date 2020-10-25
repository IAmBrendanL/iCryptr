//
//  SettingsViewController.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 3/11/18.
//  Copyright © 2018 Brendan Lindsey. All rights reserved.
//

import Foundation
import UIKit

class SettingsViewController: UITableViewController {
    
    
    // IBActions
    @IBAction func dismissWhenDone() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func setDefaultPassword() {
        getPin {
            verifyIdentity(ReasonForAuthenticating: "Authorize changing default password") {
                // Set up alert controller to get password
                let alert = UIAlertController(title: "Enter Password", message: nil, preferredStyle: .alert)
                // set default password on save
                let alertSaveAction = UIAlertAction(title: "Submit", style: .default) { action in
                    guard let passwordField = alert.textFields?[0], let password = passwordField.text else { return }
                    let _ = setDefaultPasswordInKeychain(withPassword: password, forAccount: ".password")
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
                self.present(alert, animated: true)
            }
        }
    }
    
    @IBAction func showDefaultPassword() {
        getPin {
            verifyIdentity(ReasonForAuthenticating: "Authorize viewing of default password") {
                let passwd = getPasswordFromKeychain(forAccount: ".password")
                print("password")
                print(passwd!)
                let alert = UIAlertController(title: "Default Password", message: passwd, preferredStyle: .alert)
                let alertOKAction = UIAlertAction(title: "OK", style: .default)
                alert.addAction(alertOKAction)
                alert.preferredAction = alertOKAction
                self.present(alert, animated: true)
            }
        }
    }
    
    @IBAction func setPinAndNewPassword() {
        // Set up alert controller to get password
        let alert = UIAlertController(title: "Enter Pin and Password",
                                      message: "WARNING: This will overwrite the current saved default password so be certain you know what it is.",
                                      preferredStyle: .alert)
        // set pin and default password on save
        let alertSaveAction = UIAlertAction(title: "Submit", style: .default) { action in
            guard let pinField = alert.textFields?[0], let pin = pinField.text else { return }
            guard let passwordField = alert.textFields?[1], let password = passwordField.text else { return }
            let _ = setDefaultPasswordInKeychain(withPassword: pin, forAccount: ".pin")
            let _ = setDefaultPasswordInKeychain(withPassword: password, forAccount: ".password")
        }
        let alertCancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        // build alert from parts
        alert.addTextField { pinField in
            pinField.placeholder = "Pin"
            pinField.clearButtonMode = .whileEditing
            pinField.isSecureTextEntry = true
            pinField.autocapitalizationType = .none
            pinField.autocorrectionType = .no
            pinField.keyboardType = .numberPad
        }
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
        self.present(alert, animated: true)
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
    
}
