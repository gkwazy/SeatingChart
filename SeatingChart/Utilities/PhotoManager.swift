//
//  PhotoManager.swift
//  SeatingChart
//
//  Created by GKWazy Software
//

import Foundation
import UIKit
import SwiftUI
import PhotosUI

class PhotoManager {
    static let shared = PhotoManager()

    private init() {}

    /// Compress and resize an image for storage
    func processImage(_ image: UIImage) -> UIImage? {
        let maxSize = Constants.maxPhotoSize

        // Calculate new size maintaining aspect ratio
        var newSize = image.size
        if newSize.width > maxSize || newSize.height > maxSize {
            let ratio = max(newSize.width / maxSize, newSize.height / maxSize)
            newSize.width /= ratio
            newSize.height /= ratio
        }

        // Resize image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }

    /// Create a blurred version of an image for privacy mode
    func blurImage(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(20.0, forKey: kCIInputRadiusKey)

        guard let outputImage = filter?.outputImage else { return nil }

        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }

    /// Generate a placeholder image with initials
    func generatePlaceholder(for name: String) -> UIImage {
        let initials = name.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0).uppercased() }
            .joined()

        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Background
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 80, weight: .bold),
                .foregroundColor: UIColor.white
            ]

            let text = initials.isEmpty ? "?" : initials
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            text.draw(in: textRect, withAttributes: attributes)
        }
    }
}

// MARK: - PhotosPicker Support

struct PhotoPickerItem: Transferable {
    let image: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            guard let uiImage = UIImage(data: data) else {
                throw PhotoPickerError.invalidImage
            }
            return PhotoPickerItem(image: uiImage)
        }
    }
}

enum PhotoPickerError: Error {
    case invalidImage
}
