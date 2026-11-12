//
//  ProfileViewModel.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/11/26.
//

import UIKit
import FirebaseFirestore

final class ProfileViewModel {

    // MARK: - Properties

    private let userService: UserServiceProtocol

    private var listener: ListenerRegistration?
    private var isLoggingOut = false

    private(set) var user: User?

    // MARK: - Outputs

    var onUserUpdated: (() -> Void)?
    var onLoadingStateChange: ((Bool) -> Void)?
    var onLogout: (() -> Void)?
    var onError: ((String) -> Void)?

    // MARK: - Init

    init(userService: UserServiceProtocol = UserService()) {
        self.userService = userService
    }

    deinit {
        listener?.remove()
    }

    // MARK: - Profile

    func startListening() {

        guard let currentUser = SessionManager.shared.currentUser else {
            return
        }

        user = currentUser
        onUserUpdated?()

        listener?.remove()

        listener = userService.listenForUser(uid: currentUser.uid) { [weak self] result in

            DispatchQueue.main.async {

                guard let self = self,
                      case .success(let user) = result else { return }

                self.user = user
                self.onUserUpdated?()
            }
        }
    }

    func uploadPhoto(_ image: UIImage) {

        guard let uid = SessionManager.shared.currentUserId else { return }

        onLoadingStateChange?(true)

        // Small enough to load quickly everywhere the photo is shown.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in

            let photoData = image.jpegData(maxDimension: 400, maxBytes: 150_000)

            DispatchQueue.main.async {

                guard let self = self else { return }

                guard let photoData = photoData else {
                    self.onLoadingStateChange?(false)
                    self.onError?("Couldn't use this photo. Please try another one.")
                    return
                }

                self.userService.updatePhoto(photoData, uid: uid) { [weak self] error in

                    DispatchQueue.main.async {

                        self?.onLoadingStateChange?(false)

                        if let error = error {
                            self?.onError?(error.localizedDescription)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Logout

    func logout() {

        guard !isLoggingOut else { return }

        isLoggingOut = true
        onLoadingStateChange?(true)

        var didFinish = false

        let finishLogout = { [weak self] in

            guard !didFinish else { return }
            didFinish = true

            self?.onLoadingStateChange?(false)
            self?.isLoggingOut = false

            do {
                try SessionManager.shared.logout()
                self?.onLogout?()
            } catch {
                self?.onError?(error.localizedDescription)
            }
        }

        // Mark the user offline before signing out (after that the write
        // isn't allowed). Don't wait more than 2 seconds if offline.
        PresenceService.shared.setOnline(false) {
            DispatchQueue.main.async(execute: finishLogout)
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 2,
            execute: finishLogout
        )
    }
}
