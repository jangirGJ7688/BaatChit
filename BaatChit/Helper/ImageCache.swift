//
//  ImageCache.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 11/11/26.
//

import UIKit

/// Decodes image data once and keeps the result, so scrolling doesn't
/// decode the same photo again and again.
final class ImageCache {

    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {}

    func image(
        forKey key: String,
        data: Data?
    ) -> UIImage? {

        if let cachedImage = cache.object(forKey: key as NSString) {
            return cachedImage
        }

        guard let data = data,
              let image = UIImage(data: data) else {
            return nil
        }

        cache.setObject(image, forKey: key as NSString)

        return image
    }
}
