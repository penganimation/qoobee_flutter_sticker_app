//
//  UIAlertController+Additions.swift
//  QooBeeAgapiWAStickerApp
//
//  Created by Utsav Shrestha on 09/10/2021.
//
import UIKit

extension UIAlertController {
    func addImageView(withImage image: UIImage, animated: Bool) {
        let stickerImageViewLength: CGFloat = 125.0
        let stickerImageView = UIImageView(image: image)
        stickerImageView.translatesAutoresizingMaskIntoConstraints = false

        if animated, let images = image.images {
            stickerImageView.animationImages = images
            stickerImageView.animationDuration = image.duration
            stickerImageView.startAnimating()
        }

        view.addSubview(stickerImageView)

        NSLayoutConstraint.activate([
            stickerImageView.widthAnchor.constraint(equalToConstant: stickerImageViewLength),
            stickerImageView.heightAnchor.constraint(equalToConstant: stickerImageViewLength),
            stickerImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10.0),
            stickerImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}

extension UIView {
    func circle() {
        self.layer.cornerRadius = self.frame.size.width / 2
        self.clipsToBounds = true
    }

    // Use `static let` for the associated object key
    fileprivate struct AssociatedObjectKeys {
        static let tapGestureRecognizer = UnsafeRawPointer(bitPattern: "MediaViewerAssociatedObjectKey_mediaViewer".hashValue)!
    }

    fileprivate typealias Action = () -> Void

    // Computed property to store the tap gesture action
    fileprivate var tapGestureRecognizerAction: Action? {
        get {
            return objc_getAssociatedObject(self, AssociatedObjectKeys.tapGestureRecognizer) as? Action
        }
        set {
            // Unwrap `newValue` explicitly to avoid coercion
            objc_setAssociatedObject(self, AssociatedObjectKeys.tapGestureRecognizer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Adds a tap gesture recognizer to the view and associates the provided closure as its action.
    public func addTapGestureRecognizer(action: (() -> Void)?) {
        self.isUserInteractionEnabled = true
        self.tapGestureRecognizerAction = action
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        self.addGestureRecognizer(tapGestureRecognizer)
    }

    /// Handles the tap gesture and invokes the associated action.
    @objc fileprivate func handleTapGesture(sender: UITapGestureRecognizer) {
        guard let action = self.tapGestureRecognizerAction else {
            print("No action associated with the tap gesture.")
            return
        }
        action() // Execute the unwrapped closure
    }
}

