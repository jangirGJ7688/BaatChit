//
//  UIImage+Upload.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/11/26.
//

import UIKit

extension UIImage {

    /// Scales the image down so its longest side is at most `maxDimension`,
    /// then lowers the JPEG quality until it fits in `maxBytes`.
    /// Returns nil if it can't be made small enough.
    func jpegData(
        maxDimension: CGFloat,
        maxBytes: Int
    ) -> Data? {

        let longestSide = max(size.width, size.height)

        guard longestSide > 0 else { return nil }

        let scale = min(1, maxDimension / longestSide)

        let targetSize = CGSize(
            width: (size.width * scale).rounded(),
            height: (size.height * scale).rounded()
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        let resizedImage = UIGraphicsImageRenderer(
            size: targetSize,
            format: format
        ).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }

        var quality: CGFloat = 0.8

        while quality >= 0.2 {

            if let data = resizedImage.jpegData(compressionQuality: quality),
               data.count <= maxBytes {
                return data
            }

            quality -= 0.15
        }

        return nil
    }
}
