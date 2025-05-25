//
//  ImageData.swift
//  QooBeeAgapiWAStickerApp
//
//  Created by Utsav Shrestha on 09/10/2021.
//

import UIKit

// CGSize extension to add comparison operators for width and height.
extension CGSize {

    // Checks if two CGSize objects are equal.
    public static func ==(left: CGSize, right: CGSize) -> Bool {
        return left.width.isEqual(to: right.width) && left.height.isEqual(to: right.height)
    }

    // Checks if left CGSize is smaller than right CGSize in both dimensions.
    public static func <(left: CGSize, right: CGSize) -> Bool {
        return left.width.isLess(than: right.width) && left.height.isLess(than: right.height)
    }

    // Checks if left CGSize is larger than right CGSize in both dimensions.
    public static func >(left: CGSize, right: CGSize) -> Bool {
        return !left.width.isLessThanOrEqualTo(right.width) && !left.height.isLessThanOrEqualTo(right.height)
    }

    // Checks if left CGSize is less than or equal to right CGSize in both dimensions.
    public static func <=(left: CGSize, right: CGSize) -> Bool {
        return left.width.isLessThanOrEqualTo(right.width) && left.height.isLessThanOrEqualTo(right.height)
    }

    // Checks if left CGSize is greater than or equal to right CGSize in both dimensions.
    public static func >=(left: CGSize, right: CGSize) -> Bool {
        return !left.width.isLess(than: right.width) && !left.height.isLess(than: right.height)
    }
}

// Enum representing supported image extensions for sticker images.
enum ImageDataExtension: String {
    case png = "png"
    case webp = "webp"
}

// Class to represent sticker image data, including its type, size, and animation properties.
class ImageData {
    let data: Data                   // Raw image data
    let type: ImageDataExtension      // Type of image (png or webp)

    // The size of the image data in bytes
    var bytesSize: Int64 {
        return Int64(data.count)
    }

    // Lazy property to check if the image is animated (only applies to WebP images)
    lazy var animated: Bool = {
        if type == .webp {
            return WebPManager.shared.isAnimated(webPData: data)
        } else {
            return false
        }
    }()

    // Lazy property to get the minimum frame duration for an animated image in milliseconds.
    lazy var minFrameDuration: Double = {
        return WebPManager.shared.minFrameDuration(webPData: data) * 1000
    }()

    // Lazy property to get the total animation duration for an animated image in milliseconds.
    lazy var totalAnimationDuration: Double = {
        return WebPManager.shared.totalAnimationDuration(webPData: data) * 1000
    }()

    // Lazy property to get the WebP data representation of the current image.
    // If the image is already in WebP format, it returns the data directly;
    // otherwise, it converts the PNG data to WebP format.
    lazy var webpData: Data? = {
        if type == .webp {
            return data
        } else {
            return WebPManager.shared.encode(pngData: data)
        }
    }()

    // Lazy property to return a UIImage representation of the current image data.
    // If the image is WebP, it handles animated and static frames separately.
    lazy var image: UIImage? = {
        if type == .webp {
            guard let images = WebPManager.shared.decode(webPData: data) else {
                return nil
            }
            if images.count == 0 {
                return nil
            }
            if images.count == 1 {
                return images.first
            }
            return UIImage.animatedImage(with: images, duration: WebPManager.shared.totalAnimationDuration(webPData: data))
        } else {
            // Static image
            return UIImage(data: data)
        }
    }()

    // Resizes the current image to a specified size.
    func image(withSize size: CGSize) -> UIImage? {
        guard let image = image else { return nil }

        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resizedImage
    }

    // Initializer for ImageData, taking raw data and the image type as parameters.
    init(data: Data, type: ImageDataExtension) {
        self.data = data
        self.type = type
    }

    // Validates if the image data is compliant with WhatsApp sticker requirements.
    // This function reads the data from a file path.
    static func imageDataIfCompliant(contentsOfFile filename: String, isTray: Bool) throws -> ImageData {
        let fileExtension: String = (filename as NSString).pathExtension

        guard let imageURL = Bundle.main.url(forResource: filename, withExtension: "") else {
            throw StickerPackError.fileNotFound
        }

        let data = try Data(contentsOf: imageURL)
        guard let imageType = ImageDataExtension(rawValue: fileExtension) else {
            throw StickerPackError.unsupportedImageFormat(fileExtension)
        }

        return try ImageData.imageDataIfCompliant(rawData: data, extensionType: imageType, isTray: isTray)
    }

    // Validates if the raw image data complies with WhatsApp sticker requirements.
    static func imageDataIfCompliant(rawData: Data, extensionType: ImageDataExtension, isTray: Bool) throws -> ImageData {
        let imageData = ImageData(data: rawData, type: extensionType)

        // Ensure the image data has a non-zero byte size.
        guard imageData.bytesSize > 0 else {
            throw StickerPackError.invalidImage
        }
        
        // Validation for tray images
        if isTray {
            guard !imageData.animated else {
                throw StickerPackError.animatedImagesNotSupported
            }

            guard imageData.bytesSize <= Limits.MaxTrayImageFileSize else {
                throw StickerPackError.imageTooBig(imageData.bytesSize, false)
            }

            guard imageData.image!.size == Limits.TrayImageDimensions else {
                throw StickerPackError.incorrectImageSize(imageData.image!.size)
            }
        } else {
            // Validation for stickers
            let isAnimated = imageData.animated
            guard (isAnimated && imageData.bytesSize <= Limits.MaxAnimatedStickerFileSize) ||
                  (!isAnimated && imageData.bytesSize <= Limits.MaxStaticStickerFileSize) else {
                throw StickerPackError.imageTooBig(imageData.bytesSize, isAnimated)
            }

            // Ensure image dimensions comply with limits
            if let data = imageData.image {
                guard data.size == Limits.ImageDimensions else {
                    throw StickerPackError.incorrectImageSize(imageData.image!.size)
                }
            }

            // Check animation constraints for animated images
            if isAnimated {
                guard imageData.minFrameDuration >= Double(Limits.MinAnimatedStickerFrameDurationMS) else {
                    throw StickerPackError.minFrameDurationTooShort(imageData.minFrameDuration)
                }

                guard imageData.totalAnimationDuration <= Double(Limits.MaxAnimatedStickerTotalDurationMS) else {
                    throw StickerPackError.totalAnimationDurationTooLong(imageData.totalAnimationDuration)
                }
            }
        }

        return imageData
    }
}

