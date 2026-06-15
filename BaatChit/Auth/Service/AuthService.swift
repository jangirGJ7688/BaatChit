//
//  AuthService.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/06/26.
//

import Foundation
import FirebaseAuth

protocol AuthServiceProtocol {

    func login(
        email: String,
        password: String,
        completion: @escaping(Result<User, Error>) -> Void
    )

    func signUp(
        name: String,
        email: String,
        password: String,
        completion: @escaping(Result<User, Error>) -> Void
    )

    func resetPassword(
        email: String,
        completion: @escaping(Result<Void, Error>) -> Void
    )

    func logout() throws
}

final class AuthService: AuthServiceProtocol {

    func login(
        email: String,
        password: String,
        completion: @escaping(Result<User, Error>) -> Void
    ) {

        Auth.auth().signIn(
            withEmail: email,
            password: password
        ) { result, error in

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let firebaseUser = result?.user else {
                return
            }

            let user = User(
                uid: firebaseUser.uid,
                email: firebaseUser.email ?? "",
                name: firebaseUser.displayName ?? ""
            )

            completion(.success(user))
        }
    }

    func signUp(
        name: String,
        email: String,
        password: String,
        completion: @escaping(Result<User, Error>) -> Void
    ) {

        Auth.auth().createUser(
            withEmail: email,
            password: password
        ) { result, error in

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let firebaseUser = result?.user else {
                return
            }

            let changeRequest = firebaseUser.createProfileChangeRequest()
            changeRequest.displayName = name

            changeRequest.commitChanges { _ in }

            let user = User(
                uid: firebaseUser.uid,
                email: email,
                name: name
            )

            completion(.success(user))
        }
    }

    func resetPassword(
        email: String,
        completion: @escaping(Result<Void, Error>) -> Void
    ) {

        Auth.auth().sendPasswordReset(
            withEmail: email
        ) { error in

            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func logout() throws {
        try Auth.auth().signOut()
    }
}
