//
//  AppCoordinator.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/06/26.
//

import UIKit

final class AppCoordinator: Coordinator {

    let navigationController: UINavigationController

    init(
        navigationController: UINavigationController
    ) {
        self.navigationController = navigationController
    }

    func start() {
        showSplash()
    }
}

extension AppCoordinator {
    
    func showSplash() {

        let splashVC = SplashViewController()

        splashVC.onNavigationRequired = { [weak self] destination in

            switch destination {

            case .home:
                self?.showHome()

            case .login:
                self?.showLogin()
            }
        }

        navigationController.setViewControllers(
            [splashVC],
            animated: false
        )
    }

    func showLogin() {

        let loginVC = LoginViewController()

        loginVC.onLoginSuccess = { [weak self] in
            self?.showHome()
        }

        loginVC.onSignupTapped = { [weak self] in
            self?.showSignup()
        }

        loginVC.onForgotPasswordTapped = { [weak self] in
            self?.showForgotPassword()
        }

        navigationController.setViewControllers(
            [loginVC],
            animated: false
        )
    }

    func showSignup() {

        let signupVC = SignupViewController()

        signupVC.onSignupSuccess = { [weak self] in
            self?.showHome()
        }

        signupVC.onLoginTapped = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }

        navigationController.pushViewController(
            signupVC,
            animated: true
        )
    }

    func showForgotPassword() {

        let forgotVC = ForgotPasswordViewController()

        forgotVC.onBackToLogin = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }

        navigationController.pushViewController(
            forgotVC,
            animated: true
        )
    }

    func showHome() {

        let chatListVC = HomeViewController()

//        chatListVC.onLogout = { [weak self] in
//
//            self?.showLogin()
//        }

        navigationController.setViewControllers(
            [chatListVC],
            animated: true
        )
    }
}
