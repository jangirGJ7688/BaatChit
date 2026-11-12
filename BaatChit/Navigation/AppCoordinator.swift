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

        chatListVC.onChatSelected = { [weak self] user in

            self?.showChat(with: user)
        }

        chatListVC.onNewChatTapped = { [weak self] in

            self?.showNewChat()
        }

        chatListVC.onProfileTapped = { [weak self] in

            self?.showProfile()
        }

        chatListVC.onIncomingMessage = { [weak self] item in

            self?.showMessageBanner(for: item)
        }

        navigationController.setViewControllers(
            [chatListVC],
            animated: true
        )
    }

    func showNewChat() {

        let newChatVC = NewChatViewController()
        let newChatNavigationController = UINavigationController(
            rootViewController: newChatVC
        )

        newChatVC.onUserSelected = { [weak self, weak newChatNavigationController] user in

            newChatNavigationController?.dismiss(animated: true) {
                self?.showChat(with: user)
            }
        }

        newChatVC.onCancel = { [weak newChatNavigationController] in

            newChatNavigationController?.dismiss(animated: true)
        }

        navigationController.present(
            newChatNavigationController,
            animated: true
        )
    }

    func showProfile() {

        let profileVC = ProfileViewController()

        profileVC.onLogout = { [weak self] in

            self?.showLogin()
        }

        navigationController.pushViewController(
            profileVC,
            animated: true
        )
    }

    /// Shows a banner for a new message, unless that chat or the chat list
    /// is already on screen.
    func showMessageBanner(for item: ChatListItem) {

        let topViewController = navigationController.topViewController

        let isChatOpen = (topViewController as? ChatViewController)?.otherUserId == item.otherUser.uid
        let isChatListVisible = topViewController is HomeViewController
        && navigationController.presentedViewController == nil

        guard !isChatOpen,
              !isChatListVisible,
              let window = navigationController.view.window else {
            return
        }

        InAppBanner.show(
            from: item.otherUser,
            message: item.lastMessage,
            in: window
        ) { [weak self] in

            self?.openChatFromBanner(with: item.otherUser)
        }
    }

    func openChatFromBanner(with user: User) {

        navigationController.presentedViewController?.dismiss(animated: false)
        navigationController.popToRootViewController(animated: false)

        showChat(with: user)
    }

    func showChat(with user: User) {

        guard let currentUserId = SessionManager.shared.currentUserId else {
            showLogin()
            return
        }

        let chatVC = ChatViewController(
            viewModel: ChatViewModel(
                otherUser: user,
                currentUserId: currentUserId
            )
        )

        navigationController.pushViewController(
            chatVC,
            animated: true
        )
    }
}
