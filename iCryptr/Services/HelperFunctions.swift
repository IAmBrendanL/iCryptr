//
//  HelperFunctions.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 7/17/18.
//  Copyright © 2018 Brendan Lindsey. All rights reserved.
//

import Foundation
import UIKit


/// Convience Method for presenting an alert
///
/// - Parameters:
///   - messageTitle: A String with the title for the alert
///   - messageContent: Any additional content
///   - parent: A parent view controller used to root the alert in the view hierarchy
func messageAlert (messageTitle: String, messageContent: String, parent: UIViewController) {
    let alert = UIAlertController(title: messageTitle, message: messageTitle, preferredStyle: .alert)
    let alertAction = UIAlertAction(title: "Dismiss", style: .default)
    alert.addAction(alertAction)
    parent.present(alert, animated: true)
}
