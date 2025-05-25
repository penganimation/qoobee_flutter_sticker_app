//
//  WebPManager.swift
//  QooBeeAgapiWAStickerApp
//
//  Created by Utsav Shrestha on 09/10/2021.
//

import UIKit

/// WebPManager is a singleton class responsible for handling operations
/// related to WebP image data, including decoding, checking animation,
/// and encoding PNG data into WebP format.
class WebPManager {

    // Singleton instance of WebPManager
    static let shared: WebPManager = WebPManager()

    /// Checks if the WebP data represents an animated image.
    /// - Parameter data: The WebP image data.
    /// - Returns: A Boolean indicating whether the WebP image is animated.
    func isAnimated(webPData data: Data) -> Bool {
        // Initializes a WebP image decoder with the given data and default scale.
        guard let decoder = YYImageDecoder(data: data, scale: 1.0) else { return false }

        // Returns true if the image has more than one frame, indicating animation.
        return decoder.frameCount > 1
    }

    /// Finds the minimum frame duration for an animated WebP image.
    /// - Parameter data: The WebP image data.
    /// - Returns: The minimum frame duration of the animation in seconds, or -1 if not animated.
    func minFrameDuration(webPData data: Data) -> TimeInterval {
        // Initializes a WebP image decoder with the given data.
        guard let decoder = YYImageDecoder(data: data, scale: 1.0) else { return -1 }
        // Returns -1 if the image has only one frame (not animated).
        guard decoder.frameCount > 1 else { return -1 }

        // Starts with the duration of the first frame as the minimum.
        var minFrameDuration = decoder.frameDuration(at: 0)
        
        // Iterates through all frames to find the minimum frame duration.
        for index in 1..<decoder.frameCount {
            let frameDuration = decoder.frameDuration(at: index)
            if frameDuration < minFrameDuration {
                minFrameDuration = frameDuration
            }
        }

        return minFrameDuration
    }

    /// Calculates the total duration of an animated WebP image.
    /// - Parameter data: The WebP image data.
    /// - Returns: The total duration of the animation in seconds, or -1 if not animated.
    func totalAnimationDuration(webPData data: Data) -> TimeInterval {
        // Initializes a WebP image decoder with the given data.
        guard let decoder = YYImageDecoder(data: data, scale: 1.0) else { return -1 }
        // Returns -1 if the image has only one frame (not animated).
        guard decoder.frameCount > 1 else { return -1 }

        // Initializes the total duration with the duration of the first frame.
        var totalAnimationDuration = decoder.frameDuration(at: 0)
        
        // Sums the duration of all frames to calculate the total animation duration.
        for index in 1..<decoder.frameCount {
            totalAnimationDuration += decoder.frameDuration(at: index)
        }

        return totalAnimationDuration
    }

    /// Decodes WebP data into an array of UIImages representing each frame of the animation.
    /// - Parameter data: The WebP image data.
    /// - Returns: An array of UIImages, each representing a frame, or nil if decoding fails.
    func decode(webPData data: Data) -> [UIImage]? {
        // Initializes a WebP image decoder with the given data.
        guard let decoder = YYImageDecoder(data: data, scale: 1.0) else { return nil }

        // Array to store the decoded images.
        var images: [UIImage] = []
        
        // Decodes each frame and adds it to the images array.
        for index in 0..<decoder.frameCount {
            guard let frame = decoder.frame(at: index, decodeForDisplay: true) else {
                continue // Skips frames that fail to decode.
            }
            guard let image = frame.image else {
                continue // Skips frames without an image.
            }
            images.append(image)
        }
        
        // Returns nil if no frames were decoded.
        if images.isEmpty {
            return nil
        }
        
        return images
    }

    /// Encodes PNG data into WebP format.
    /// - Parameter data: The PNG image data.
    /// - Returns: The encoded WebP data, or nil if encoding fails.
    func encode(pngData data: Data) -> Data? {
        // Initializes a WebP image encoder.
        guard let encoder = YYImageEncoder(type: YYImageType.webP) else { return nil }

        // Adds the PNG data as a frame to the encoder with a duration of 0.0 (static image).
        encoder.addImage(with: data, duration: 0.0)
        
        // Returns the encoded WebP data.
        return encoder.encode()
    }
}

