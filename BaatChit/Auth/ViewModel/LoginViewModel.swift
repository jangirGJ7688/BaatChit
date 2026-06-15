//
//  LoginViewModel.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/06/26.
//

import Foundation
import Firebase

final class LoginViewModel {

    // MARK: - Properties

    private let authService: AuthServiceProtocol

    // MARK: - Outputs

    var onLoadingStateChange: ((Bool) -> Void)?
    var onLoginSuccess: (() -> Void)?
    var onError: ((String) -> Void)?

    // MARK: - Init

    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
    }

    // MARK: - Login

    func login(
        email: String?,
        password: String?
    ) {

        guard validateInputs(
            email: email,
            password: password
        ) else {
            return
        }

        guard let email = email,
              let password = password else {
            return
        }

        onLoadingStateChange?(true)

        authService.login(
            email: email,
            password: password
        ) { [weak self] result in

            DispatchQueue.main.async {

                guard let self = self else { return }

                self.onLoadingStateChange?(false)

                switch result {

                case .success:

                    self.onLoginSuccess?()

                case .failure(let error):

                    self.onError?(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Validation

private extension LoginViewModel {

    func validateInputs(
        email: String?,
        password: String?
    ) -> Bool {

        guard let email = email,
              !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {

            onError?("Please enter email address")
            return false
        }

        guard isValidEmail(email) else {

            onError?("Please enter a valid email address")
            return false
        }

        guard let password = password,
              !password.isEmpty else {

            onError?("Please enter password")
            return false
        }

        guard password.count >= 6 else {

            onError?("Password must be at least 6 characters")
            return false
        }

        return true
    }

    func isValidEmail(
        _ email: String
    ) -> Bool {

        let emailRegex =
        "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"

        let emailPredicate = NSPredicate(
            format: "SELF MATCHES %@",
            emailRegex
        )

        return emailPredicate.evaluate(with: email)
    }
}
