//
//  AlertCenter.swift
//  QooBeeWAStickers
//
//  Created by lu peng on 8/1/20.
//  Copyright © 2020 WhatsApp. All rights reserved.
//

import Foundation
import UIKit

/// Enum for displaying various types of alerts in the app.
enum Alert {
    
    /**
     Displays a basic alert with "OK" and "CANCEL" options.
     
     - Parameters:
       - vc: The view controller from which the alert will be presented.
       - title: The title of the alert.
       - message: The message body of the alert.
     */
    private static func showBasicReactAlert(vc: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "CANCEL", style: .default, handler: nil))
        vc.present(alert, animated: true)
    }
    
    /**
     Displays a purchasing alert with a loading spinner.
     
     - Parameter vc: The view controller from which the alert will be presented.
     */
    static func showPurchasingAlert(vc: UIViewController) {
        let purchasingAlert = UIAlertController(title: "Processing", message: "\n\n", preferredStyle: .alert)
        purchasingAlert.addSpinner()
        vc.present(purchasingAlert, animated: true, completion: nil)
    }
    
    /**
     Displays a restoring alert with a loading spinner.
     
     - Parameter vc: The view controller from which the alert will be presented.
     */
    static func showRestoringAlert(vc: UIViewController) {
        let restoringAlert = UIAlertController(title: "Restoring Stickers", message: "\n\n", preferredStyle: .alert)
        restoringAlert.addSpinner()
        vc.present(restoringAlert, animated: true, completion: nil)
    }
    
    /**
     Displays an alert to confirm the purchase of all stickers, including future updates.
     
     - Parameter vc: The view controller from which the alert will be presented.
     */
    static func showBuyingAllAlert(vc: UIViewController) {
        let totalStickers = StickerModel.shared.getTotalNumOfStickers()
        let message = "This deal includes ALL \(totalStickers) stickers & ALL future updates to this App. Do you want to proceed?"
        
        let buyAllAlertController = UIAlertController(title: "Purchase Info", message: message, preferredStyle: .alert)
        buyAllAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Initiate the purchase on "OK" action
        buyAllAlertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            IAPHelper.shared.buyProduct("com.qoobee.qoobeestickersanimated.MessageExtension.BUNDLESALE")
        }))
        
        vc.present(buyAllAlertController, animated: true, completion: nil)
    }
    
    /**
     Displays an alert indicating a sticker has been added to favorites, with a loading spinner.
     
     - Parameter vc: The view controller from which the alert will be presented.
     */
    static func showAddedToFavAlert(vc: UIViewController) {
        let addedToFavAlert = UIAlertController(title: "Adding to Favorites", message: "\n\n", preferredStyle: .alert)
        addedToFavAlert.addSpinner()
        vc.present(addedToFavAlert, animated: true, completion: nil)
    }
    
    /**
     Displays an alert indicating a sticker is already added to favorites, with a loading spinner.
     
     - Parameter vc: The view controller from which the alert will be presented.
     */
    static func showAlreadyAddedAlert(vc: UIViewController) {
        let alreadyAddedAlert = UIAlertController(title: "Already Added", message: "\n\n", preferredStyle: .alert)
        alreadyAddedAlert.addSpinner()
        vc.present(alreadyAddedAlert, animated: true, completion: nil)
    }
    
    /**
     Displays an alert indicating a sticker has been removed from favorites, with a loading spinner.
     
     - Parameter vc: The view controller from which the alert will be presented.
     */
    static func showRemovedFromFavAlert(vc: UIViewController) {
        let removedFromFavAlert = UIAlertController(title: "Removed", message: "\n\n", preferredStyle: .alert)
        removedFromFavAlert.addSpinner()
        vc.present(removedFromFavAlert, animated: true, completion: nil)
    }
}

// MARK: - UIAlertController Extension

extension UIAlertController {
    
    /**
     Adds a loading spinner to the UIAlertController, commonly used for processing alerts.
     */
    func addSpinner() {
        let activity = UIActivityIndicatorView(style: .medium)
        activity.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activity)
        
        // Set up the activity indicator's layout constraints
        activity.addConstraint(NSLayoutConstraint(item: activity, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: activity.bounds.size.width))
        activity.addConstraint(NSLayoutConstraint(item: activity, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: activity.bounds.size.height))
        view.addConstraint(NSLayoutConstraint(item: activity, attribute: .centerXWithinMargins, relatedBy: .equal, toItem: view, attribute: .centerXWithinMargins, multiplier: 1.0, constant: 0.0))
        view.addConstraint(NSLayoutConstraint(item: activity, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottomMargin, multiplier: 1.0, constant: -20.0))
        
        activity.startAnimating()
    }
}

