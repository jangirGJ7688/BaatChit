//
//  PresenceService.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/11/26.
//

import Foundation
import FirebaseFirestore

/// Saves whether the current user is online, and when they were last seen.
final class PresenceService {

    static let shared = PresenceService()

    private init() {}

    /// `completion` runs once the server has saved the change (or right
    /// away when nobody is logged in).
    func setOnline(
        _ isOnline: Bool,
        completion: (() -> Void)? = nil
    ) {

        guard let uid = SessionManager.shared.currentUserId else {
            completion?()
            return
        }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .setData(
                [
                    "isOnline": isOnline,
                    "lastSeen": FieldValue.serverTimestamp()
                ],
                merge: true
            ) { _ in

                completion?()
            }
    }
}
