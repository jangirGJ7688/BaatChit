//
//  SessionManager.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/06/26.
//

import FirebaseAuth

final class SessionManager {

    static let shared = SessionManager()

    private init() {}

    var isLoggedIn: Bool {
        Auth.auth().currentUser != nil
    }

    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    func logout() throws {
        try Auth.auth().signOut()
    }
}
