//
//  NewChatViewModel.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/11/26.
//

import Foundation
import FirebaseFirestore

final class NewChatViewModel {

    // MARK: - Properties

    private let userService: UserServiceProtocol

    private var listener: ListenerRegistration?

    private(set) var users: [User] = []

    // MARK: - Outputs

    var onLoadingStateChange: ((Bool) -> Void)?
    var onUsersUpdated: (() -> Void)?
    var onError: ((String) -> Void)?

    // MARK: - Init

    init(userService: UserServiceProtocol = UserService()) {
        self.userService = userService
    }

    deinit {
        listener?.remove()
    }

    // MARK: - Users

    func startListening() {

        guard let currentUserId = SessionManager.shared.currentUserId else {
            return
        }

        listener?.remove()

        onLoadingStateChange?(true)

        listener = userService.listenForUsers { [weak self] result in

            DispatchQueue.main.async {

                guard let self = self else { return }

                self.onLoadingStateChange?(false)

                switch result {

                case .success(let users):

                    self.users = users.filter { $0.uid != currentUserId }
                    self.onUsersUpdated?()

                case .failure(let error):

                    self.onError?(error.localizedDescription)
                }
            }
        }
    }
}
