//
//  SignupViewModel.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/06/26.
//

import Foundation

final class SignupViewModel {

    // MARK: - Properties

    private let authService: AuthServiceProtocol

    // MARK: - Outputs

    var onLoadingStateChange: ((Bool) -> Void)?
    var onSignupSuccess: (() -> Void)?
    var onError: ((String) -> Void)?

    // MARK: - Init

    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
    }

    // MARK: - Signup

    func signup(
        name: String?,
        email: String?,
        password: String?,
        confirmPassword: String?
    ) {

        guard validateInputs(
            name: name,
            email: email,
            password: password,
            confirmPassword: confirmPassword
        ) else {
            return
        }

        guard let name = name,
              let email = email,
              let password = password else {
            return
        }

        onLoadingStateChange?(true)

        authService.signUp(
            name: name,
            email: email,
            password: password
        ) { [weak self] result in

            DispatchQueue.main.async {

                guard let self = self else { return }

                self.onLoadingStateChange?(false)

                switch result {

                case .success:
                    self.onSignupSuccess?()

                case .failure(let error):
                    self.onError?(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Validation

private extension SignupViewModel {

    func validateInputs(
        name: String?,
        email: String?,
        password: String?,
        confirmPassword: String?
    ) -> Bool {

        guard let name = name,
              !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {

            onError?("Please enter your name")
            return false
        }

        guard let email = email,
              !email.isEmpty else {

            onError?("Please enter email")
            return false
        }

        guard isValidEmail(email) else {

            onError?("Please enter valid email")
            return false
        }

        guard let password = password,
              !password.isEmpty else {

            onError?("Please enter password")
            return false
        }

        guard password.count >= 6 else {

            onError?("Password should be at least 6 characters")
            return false
        }

        guard password == confirmPassword else {

            onError?("Passwords do not match")
            return false
        }

        return true
    }

    func isValidEmail(_ email: String) -> Bool {

        let regex =
        "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"

        return NSPredicate(
            format: "SELF MATCHES %@",
            regex
        ).evaluate(with: email)
    }
}
