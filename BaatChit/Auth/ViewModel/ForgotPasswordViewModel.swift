//
//  ForgotPasswordViewModel.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/06/26.
//

import Foundation

final class ForgotPasswordViewModel {

    // MARK: - Properties

    private let authService: AuthServiceProtocol

    // MARK: - Outputs

    var onLoadingStateChange: ((Bool) -> Void)?
    var onSuccess: ((String) -> Void)?
    var onError: ((String) -> Void)?

    // MARK: - Init

    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
    }

    // MARK: - Reset Password

    func resetPassword(email: String?) {

        guard let email = email,
              !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {

            onError?("Please enter email address")
            return
        }

        guard isValidEmail(email) else {

            onError?("Please enter a valid email address")
            return
        }

        onLoadingStateChange?(true)

        authService.resetPassword(email: email) { [weak self] result in

            DispatchQueue.main.async {

                guard let self = self else { return }

                self.onLoadingStateChange?(false)

                switch result {

                case .success:

                    self.onSuccess?(
                        "Password reset link has been sent to your email."
                    )

                case .failure(let error):

                    self.onError?(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Validation

private extension ForgotPasswordViewModel {

    func isValidEmail(_ email: String) -> Bool {

        let regex =
        "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"

        return NSPredicate(
            format: "SELF MATCHES %@",
            regex
        ).evaluate(with: email)
    }
}
