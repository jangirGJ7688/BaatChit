//
//  SplashViewModel.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/06/26.
//

import FirebaseAuth
import Foundation

final class SplashViewModel {

    enum Destination {
        case login
        case home
    }

    // MARK: - Outputs

    var onNavigationRequired: ((Destination) -> Void)?

    // MARK: - Authentication Check

    func checkAuthenticationStatus() {

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 2.0
        ) { [weak self] in

            guard let self = self else { return }

            if SessionManager.shared.isLoggedIn {

                self.onNavigationRequired?(.home)

            } else {

                self.onNavigationRequired?(.login)
            }
        }
    }
}
