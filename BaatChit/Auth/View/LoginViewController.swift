//
//  LoginViewController.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/06/26.
//

import UIKit

final class LoginViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: LoginViewModel

    var onLoginSuccess: (() -> Void)?
    var onSignupTapped: (() -> Void)?
    var onForgotPasswordTapped: (() -> Void)?

    private var hasAnimatedIn = false

    // MARK: - UI Components

    private let formView = AuthFormView(
        headerView: AuthHeaderView(
            title: "Welcome back 👋",
            subtitle: "Log in to continue chatting"
        )
    )

    private let emailField = FormField(
        placeholder: "Email address",
        iconName: "envelope.fill",
        kind: .email
    )

    private let passwordField = FormField(
        placeholder: "Password",
        iconName: "lock.fill",
        kind: .password
    )

    private let forgotPasswordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Forgot password?", for: .normal)
        button.titleLabel?.font = Theme.Fonts.rounded(15, weight: .semibold)
        button.contentHorizontalAlignment = .trailing
        return button
    }()

    private let messageView = InlineMessageView()

    private let loginButton = PrimaryButton(title: "Log In")

    private let signupButton = AuthFooterButton(
        question: "Don't have an account?",
        action: "Sign Up"
    )

    // MARK: - Init

    init(viewModel: LoginViewModel = LoginViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func loadView() {
        view = formView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupActions()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !hasAnimatedIn else { return }

        hasAnimatedIn = true
        formView.animateIn()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
}

// MARK: - Setup UI

private extension LoginViewController {

    func setupUI() {

        emailField.returnKeyType = .next
        passwordField.returnKeyType = .go

        [
            emailField,
            passwordField,
            forgotPasswordButton,
            messageView,
            loginButton,
            signupButton
        ].forEach {
            formView.formStack.addArrangedSubview($0)
        }

        formView.formStack.setCustomSpacing(4, after: passwordField)
        formView.formStack.setCustomSpacing(20, after: forgotPasswordButton)
        formView.formStack.setCustomSpacing(20, after: messageView)
        formView.formStack.setCustomSpacing(24, after: loginButton)
    }
}

// MARK: - Actions

private extension LoginViewController {

    func setupActions() {

        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        signupButton.addTarget(self, action: #selector(signupTapped), for: .touchUpInside)
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)

        emailField.onReturn = { [weak self] in
            self?.passwordField.becomeFirstResponder()
        }

        passwordField.onReturn = { [weak self] in
            self?.loginTapped()
        }

        // Typing again clears the last error.
        [emailField, passwordField].forEach {
            $0.onTextChange = { [weak self] in
                self?.messageView.hide()
            }
        }
    }

    @objc
    func loginTapped() {

        view.endEditing(true)

        viewModel.login(
            email: emailField.text,
            password: passwordField.text
        )
    }

    @objc
    func signupTapped() {
        onSignupTapped?()
    }

    @objc
    func forgotPasswordTapped() {
        onForgotPasswordTapped?()
    }
}

// MARK: - ViewModel Binding

private extension LoginViewController {

    func bindViewModel() {

        viewModel.onLoadingStateChange = { [weak self] isLoading in
            self?.loginButton.isLoading = isLoading
        }

        viewModel.onLoginSuccess = { [weak self] in
            Haptics.success()
            self?.onLoginSuccess?()
        }

        viewModel.onError = { [weak self] message in
            self?.messageView.show(message, style: .error)
        }
    }
}
