//
//  User.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/06/26.
//

import Foundation
import FirebaseFirestore

struct User: Equatable {
    let uid: String
    let email: String
    let name: String
    var photoData: Data? = nil
    var photoId: String? = nil
    var isOnline: Bool = false
    var lastSeen: Date? = nil
}

extension User {

    init?(dictionary: [String: Any]) {

        guard let uid = dictionary["uid"] as? String else {
            return nil
        }

        self.init(
            uid: uid,
            email: dictionary["email"] as? String ?? "",
            name: dictionary["name"] as? String ?? "",
            photoData: dictionary["photoData"] as? Data,
            photoId: dictionary["photoId"] as? String,
            isOnline: dictionary["isOnline"] as? Bool ?? false,
            lastSeen: (dictionary["lastSeen"] as? Timestamp)?.dateValue()
        )
    }

    /// Profile fields only. Photo and presence are updated separately.
    var dictionary: [String: Any] {
        [
            "uid": uid,
            "email": email,
            "name": name
        ]
    }

    var displayName: String {
        name.isEmpty ? email : name
    }

    /// Changes whenever the photo changes, so a cached photo is never stale.
    var photoCacheKey: String? {
        photoData == nil ? nil : "avatar-\(uid)-\(photoId ?? "")"
    }
}
