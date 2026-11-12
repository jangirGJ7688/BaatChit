//
//  UserService.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/11/26.
//

import Foundation
import FirebaseFirestore

protocol UserServiceProtocol {

    func saveUser(
        _ user: User,
        completion: @escaping(Error?) -> Void
    )

    func updatePhoto(
        _ photoData: Data,
        uid: String,
        completion: @escaping(Error?) -> Void
    )

    func listenForUsers(
        onChange: @escaping(Result<[User], Error>) -> Void
    ) -> ListenerRegistration

    func listenForUser(
        uid: String,
        onChange: @escaping(Result<User, Error>) -> Void
    ) -> ListenerRegistration
}

final class UserService: UserServiceProtocol {

    private let usersCollection = Firestore.firestore().collection("users")

    func saveUser(
        _ user: User,
        completion: @escaping(Error?) -> Void
    ) {

        var data = user.dictionary

        // Don't overwrite a saved name with an empty one.
        if user.name.isEmpty {
            data.removeValue(forKey: "name")
        }

        usersCollection.document(user.uid).setData(
            data,
            merge: true
        ) { error in

            completion(error)
        }
    }

    func updatePhoto(
        _ photoData: Data,
        uid: String,
        completion: @escaping(Error?) -> Void
    ) {

        // A new photoId tells everyone's image cache that the photo changed.
        usersCollection.document(uid).setData(
            [
                "photoData": photoData,
                "photoId": UUID().uuidString
            ],
            merge: true
        ) { error in

            completion(error)
        }
    }

    func listenForUsers(
        onChange: @escaping(Result<[User], Error>) -> Void
    ) -> ListenerRegistration {

        usersCollection.addSnapshotListener { snapshot, error in

            if let error = error {
                onChange(.failure(error))
                return
            }

            let users = (snapshot?.documents ?? [])
                .compactMap { User(dictionary: $0.data(with: .estimate)) }
                .sorted {
                    $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
                }

            onChange(.success(users))
        }
    }

    func listenForUser(
        uid: String,
        onChange: @escaping(Result<User, Error>) -> Void
    ) -> ListenerRegistration {

        usersCollection.document(uid).addSnapshotListener { snapshot, error in

            if let error = error {
                onChange(.failure(error))
                return
            }

            guard let data = snapshot?.data(with: .estimate),
                  let user = User(dictionary: data) else {
                return
            }

            onChange(.success(user))
        }
    }
}
