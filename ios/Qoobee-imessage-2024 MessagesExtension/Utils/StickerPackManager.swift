//
//  StickerPackManager.swift
//  QooBeeAgapiWAStickerApp
//
//  Created by Utsav Shrestha on 09/10/2021.
//

import UIKit

extension Dictionary {
    /// Returns the byte size of the dictionary when encoded.
    func bytesSize() -> Int {
        // Create a mutable data object to hold the encoded dictionary data.
        let data = NSMutableData()
        
        // Initialize NSKeyedArchiver with secure coding set to false (or true if you need secure coding).
        // Secure coding ensures that the archived data cannot be tampered with in a malicious way.
        // In this case, set to false if the dictionary doesn't require secure coding.
        let encoder = NSKeyedArchiver(requiringSecureCoding: false)
        
        // Encode the dictionary into the NSKeyedArchiver.
        encoder.encode(self, forKey: "dictionary")
        
        // Finish encoding and write the data to the mutable data object.
        encoder.finishEncoding()
        
        // Return the length of the data, which represents the byte size of the encoded dictionary.
        return data.length
    }
}


class StickerPackManager {

    static let queue: DispatchQueue = DispatchQueue(label: "stickerPackQueue")

    static func stickersJSON(contentsOfFile filename: String) throws -> [String: Any] {
        if let path = Bundle.main.path(forResource: filename, ofType: "wasticker") {
            let data: Data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
            return try JSONSerialization.jsonObject(with: data) as! [String: Any]
        }

        throw StickerPackError.fileNotFound
    }

    /**
     *  Retrieves sticker packs from a JSON dictionary.
     *  If the processing of a certain sticker pack encounters an exception (see methods in StickerPack.swift),
     *  that sticker pack won't be returned along with the rest (eg if identifer isn't unique or stickers have
     *  invalid image dimensions)
     *
     *  - Parameter dict: JSON dictionary
     *  - Parameter completionHandler: called on the main queue
     */
    static func fetchStickerPacks(fromJSON dict: [String: Any], identifier: String, completionHandler: @escaping ([StickerPack]) -> Void) {
        queue.async {
            let packs: [[String: Any]] = dict["sticker_packs"] as! [[String: Any]]
            var stickerPacks: [StickerPack] = []
            var currentIdentifiers: [String: Bool] = [:]

            let iosAppStoreLink: String? = dict["ios_app_store_link"] as? String
            let androidAppStoreLink: String? = dict["android_play_store_link"] as? String
            Interoperability.iOSAppStoreLink = iosAppStoreLink != "" ? iosAppStoreLink : nil
            Interoperability.AndroidStoreLink = androidAppStoreLink != "" ? androidAppStoreLink : nil

            for pack in packs {
                let packName: String = pack["name"] as! String
                let packPublisher: String = pack["publisher"] as! String
                let packTrayImageFileName: String = pack["tray_image_file"] as! String

                var packPublisherWebsite: String? = pack["publisher_website"] as? String
                var packPrivacyPolicyWebsite: String? = pack["privacy_policy_website"] as? String
                var packLicenseAgreementWebsite: String? = pack["license_agreement_website"] as? String
                // If the strings are empty, consider them as nil
                packPublisherWebsite = packPublisherWebsite != "" ? packPublisherWebsite : nil
                packPrivacyPolicyWebsite = packPrivacyPolicyWebsite != "" ? packPrivacyPolicyWebsite : nil
                packLicenseAgreementWebsite = packLicenseAgreementWebsite != "" ? packLicenseAgreementWebsite : nil

                // Pack identifier has to be a valid string and be unique
                let packIdentifier: String? = pack["identifier"] as? String
                if packIdentifier != nil && currentIdentifiers[packIdentifier!] == nil {
                    currentIdentifiers[packIdentifier!] = true
                } else {
                    if let packIdentifier = packIdentifier {
                        fatalError("Missing identifier or a sticker pack already has the identifier \(packIdentifier).")
                    }

                    fatalError("\(packName) must have an identifier and it must be unique.")
                }
                //Just get the pack for provided identifier
                if packIdentifier != identifier{
                    continue
                }

                let animatedStickerPack: Bool? = pack["animated_sticker_pack"] as? Bool

                var stickerPack: StickerPack?

                do {
                    stickerPack = try StickerPack(identifier: packIdentifier!, name: packName, publisher: packPublisher, trayImageFileName: packTrayImageFileName, animatedStickerPack: animatedStickerPack, publisherWebsite: packPublisherWebsite, privacyPolicyWebsite: packPrivacyPolicyWebsite, licenseAgreementWebsite: packLicenseAgreementWebsite)
                } catch StickerPackError.fileNotFound {
                    fatalError("\(packTrayImageFileName) not found.")
                } catch StickerPackError.emptyString {
                    fatalError("The name, identifier, and publisher strings can't be empty.")
                } catch StickerPackError.unsupportedImageFormat(let imageFormat) {
                    fatalError("\(packTrayImageFileName): \(imageFormat) is not a supported format.")
                } catch StickerPackError.invalidImage {
                    fatalError("Tray image file size is 0 KB.")
                } catch StickerPackError.imageTooBig(let imageFileSize, _) {
                    let roundedSize = round((Double(imageFileSize) / 1024) * 100) / 100;
                    fatalError("\(packTrayImageFileName): \(roundedSize) KB is bigger than the max tray image file size (\(Limits.MaxTrayImageFileSize / 1024) KB).")
                } catch StickerPackError.incorrectImageSize(let imageDimensions) {
                    fatalError("\(packTrayImageFileName): \(imageDimensions) is not compliant with tray dimensions requirements, \(Limits.TrayImageDimensions).")
                } catch StickerPackError.animatedImagesNotSupported {
                    fatalError("\(packTrayImageFileName) is an animated image. Animated images are not supported.")
                } catch StickerPackError.stringTooLong {
                    fatalError("Name, identifier, and publisher of sticker pack must be less than \(Limits.MaxCharLimit128) characters.")
                } catch {
                    fatalError(error.localizedDescription)
                }

                let stickers: [[String: Any]] = pack["stickers"] as! [[String: Any]]
                for sticker in stickers {
                    let emojis: [String]? = sticker["emojis"] as? [String]

                    let filename = sticker["image_file"] as! String
                    do {
                        try stickerPack!.addSticker(contentsOfFile: filename, emojis: emojis)
                    } catch StickerPackError.stickersNumOutsideAllowableRange {
                        fatalError("Sticker count outside the allowable limit (\(Limits.MaxStickersPerPack) stickers per pack).")
                    } catch StickerPackError.fileNotFound {
                        fatalError("\(filename) not found.")
                    } catch StickerPackError.unsupportedImageFormat(let imageFormat) {
                        fatalError("\(filename): \(imageFormat) is not a supported format.")
                    } catch StickerPackError.invalidImage {
                        fatalError("Image file size is 0 KB.")
                    } catch StickerPackError.imageTooBig(let imageFileSize, let animated) {
                        let roundedSize = round((Double(imageFileSize) / 1024) * 100) / 100;
                        let maxSize = animated ? Limits.MaxAnimatedStickerFileSize : Limits.MaxStaticStickerFileSize
                        fatalError("\(filename): \(roundedSize) KB is bigger than the max file size (\(maxSize / 1024) KB).")
                    } catch StickerPackError.incorrectImageSize(let imageDimensions) {
                        fatalError("\(filename): \(imageDimensions) is not compliant with sticker images dimensions, \(Limits.ImageDimensions).")
                    } catch StickerPackError.tooManyEmojis {
                        fatalError("\(filename) has too many emojis. \(Limits.MaxEmojisCount) is the maximum number.")
                    } catch StickerPackError.minFrameDurationTooShort(let minFrameDuration) {
                        let roundedDuration = round(minFrameDuration)
                        fatalError("\(filename): \(roundedDuration) ms is shorter than the min frame duration (\(Limits.MinAnimatedStickerFrameDurationMS) ms).")
                    } catch StickerPackError.totalAnimationDurationTooLong(let totalFrameDuration) {
                        let roundedDuration = round(totalFrameDuration)
                        fatalError("\(filename): \(roundedDuration) ms is longer than the max total animation duration (\(Limits.MaxAnimatedStickerTotalDurationMS) ms).")
                    } catch StickerPackError.animatedStickerPackWithStaticStickers {
                        fatalError("Animated sticker pack contains static stickers.")
                    } catch StickerPackError.staticStickerPackWithAnimatedStickers {
                        fatalError("Static sticker pack contains animated stickers.")
                    } catch {
                        fatalError(error.localizedDescription)
                    }
                }

                if stickers.count < Limits.MinStickersPerPack {
                  fatalError("Sticker count smaller that the allowable limit (\(Limits.MinStickersPerPack) stickers per pack).")
                }

                stickerPacks.append(stickerPack!)
            }

            DispatchQueue.main.async {
                completionHandler(stickerPacks)
            }
        }
    }

}

