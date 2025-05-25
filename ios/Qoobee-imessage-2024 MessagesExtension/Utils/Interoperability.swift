//
//  Interoperability.swift
//  QooBeeAgapiWAStickerApp
//
//  Created by Utsav Shrestha on 09/10/2021.
//

import UIKit

/// Utility structure for handling interoperability with WhatsApp, including sending sticker packs via pasteboard.
struct Interoperability {
    // Constants for interoperability
    private static let DefaultBundleIdentifier: String = "WA.WAStickersThirdParty" // Default bundle identifier, should be customized
    private static let PasteboardExpirationSeconds: TimeInterval = 60 // Time after which pasteboard data expires
    private static let PasteboardStickerPackDataType: String = "net.whatsapp.third-party.sticker-pack" // Data type identifier for WhatsApp sticker packs
    private static let WhatsAppURL: URL = URL(string: "whatsapp://stickerPack")! // URL to open WhatsApp with sticker pack
    
    // Optional properties for app store links
    static var iOSAppStoreLink: String?
    static var AndroidStoreLink: String?

    /// Checks if WhatsApp can be opened by verifying if its URL scheme is supported.
    /// - Returns: A boolean indicating if WhatsApp can be opened.
    static func canSend() -> Bool {
        return true // Always returns true; could be replaced with actual check if needed
        // Uncomment below line to check if WhatsApp is installed on the device
        // return UIApplication.shared.canOpenURL(URL(string: "whatsapp://")!)
    }
    
    /// Sends a JSON sticker pack to WhatsApp using UIPasteboard.
    /// - Parameter json: A dictionary representing the sticker pack data.
    /// - Returns: A boolean indicating if the sticker pack was successfully sent to the pasteboard.
    static func send(json: [String: Any]) -> Bool {
        // Ensure the bundle identifier does not contain the default WhatsApp identifier.
        if Bundle.main.bundleIdentifier?.contains(DefaultBundleIdentifier) == true {
            fatalError("Your bundle identifier must not include the default one.")
        }

        // Access the general pasteboard
        let pasteboard = UIPasteboard.general

        // Add app store links to the JSON data for interoperability
        var jsonWithAppStoreLink: [String: Any] = json
        jsonWithAppStoreLink["ios_app_store_link"] = iOSAppStoreLink
        jsonWithAppStoreLink["android_play_store_link"] = AndroidStoreLink

        // Attempt to serialize the JSON data into a format that can be sent via pasteboard
        guard let dataToSend = try? JSONSerialization.data(withJSONObject: jsonWithAppStoreLink, options: []) else {
            print("Failed to serialize JSON data for WhatsApp sticker pack.")
            return false
        }

        // Place the data in the pasteboard with an expiration time, supporting both iOS 10+ and earlier versions
        if #available(iOS 10.0, *) {
            pasteboard.setItems([[PasteboardStickerPackDataType: dataToSend]], options: [
                UIPasteboard.OptionsKey.localOnly: true,
                UIPasteboard.OptionsKey.expirationDate: NSDate(timeIntervalSinceNow: PasteboardExpirationSeconds)
            ])
        } else {
            pasteboard.setData(dataToSend, forPasteboardType: PasteboardStickerPackDataType)
        }

        // Dispatch to main queue to attempt to open WhatsApp with the sticker pack
        DispatchQueue.main.async {
            if canSend() {
                // Notify that WhatsApp should be opened. This can be observed and handled elsewhere in the app.
                NotificationCenter.default.post(name: Notification.Name("openWhatsapp"), object: nil)

                // Alternative code to directly open WhatsApp (commented out)
                // MessagesViewController.openURL(urlString: WhatsAppURL)

                // Uncomment below to use openURL for iOS 10 and earlier versions
                // if #available(iOS 10.0, *) {
                //     UIApplication.shared.open(WhatsAppURL)
                // } else {
                //     UIApplication.shared.openURL(WhatsAppURL)
                // }
            }
        }
        
        return true // Successfully sent data to pasteboard
    }

    /// Copies an image to the general pasteboard.
    /// - Parameter image: The UIImage to be copied to the pasteboard.
    static func copyImageToPasteboard(image: UIImage) {
        UIPasteboard.general.image = image // Directly sets the image to the pasteboard
    }
}

