//
//  SignupViewController.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/06/26.
//

import UIKit

final class SignupViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: SignupViewModel

    var onSignupSuccess: (() -> Void)?
    var onLoginTapped: (() -> Void)?

    private var hasAnimatedIn = false

    // MARK: - UI Components

    private let formView = AuthFormView(
        headerView: AuthHeaderView(
            title: "Create account",
            subtitle: "Join BaatChit and start chatting",
            showsBackButton: true
        )
    )

    private let nameField = FormField(
        placeholder: "Full name",
        iconName: "person.fill",
        kind: .name
    )

    private let emailField = FormField(
        placeholder: "Email address",
        iconName: "envelope.fill",
        kind: .email
    )

    private let passwordField = FormField(
        placeholder: "Password (6+ characters)",
        iconName: "lock.fill",
        kind: .newPassword
    )

    private let confirmPasswordField = FormField(
        placeholder: "Confirm password",
        iconName: "lock.rotation",
        kind: .newPassword
    )

    private let messageView = InlineMessageView()

    private let signupButton = PrimaryButton(title: "Create Account")

    private let loginButton = AuthFooterButton(
        question: "Already have an account?",
        action: "Log In"
    )

    // MARK: - Init

    init(viewModel: SignupViewModel = SignupViewModel()) {
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

private extension SignupViewController {

    func setupUI() {

        [nameField, emailField, passwordField].forEach {
            $0.returnKeyType = .next
        }

        confirmPasswordField.returnKeyType = .go

        [
            nameField,
            emailField,
            passwordField,
            confirmPasswordField,
            messageView,
            signupButton,
            loginButton
        ].forEach {
            formView.formStack.addArrangedSubview($0)
        }

        formView.formStack.setCustomSpacing(20, after: confirmPasswordField)
        formView.formStack.setCustomSpacing(20, after: messageView)
        formView.formStack.setCustomSpacing(24, after: signupButton)
    }
}

// MARK: - Actions

private extension SignupViewController {

    func setupActions() {

        signupButton.addTarget(self, action: #selector(signupTapped), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)

        formView.headerView.onBack = { [weak self] in
            self?.onLoginTapped?()
        }

        // Return moves to the next field, then submits.
        let fields = [nameField, emailField, passwordField, confirmPasswordField]

        for (index, field) in fields.enumerated() {

            field.onReturn = { [weak self] in

                if index < fields.count - 1 {
                    fields[index + 1].becomeFirstResponder()
                } else {
                    self?.signupTapped()
                }
            }

            field.onTextChange = { [weak self] in
                self?.messageView.hide()
            }
        }
    }

    @objc
    func signupTapped() {

        view.endEditing(true)

        viewModel.signup(
            name: nameField.text,
            email: emailField.text,
            password: passwordField.text,
            confirmPassword: confirmPasswordField.text
        )
    }

    @objc
    func loginTapped() {
        onLoginTapped?()
    }
}

// MARK: - ViewModel Binding

private extension SignupViewController {

    func bindViewModel() {

        viewModel.onLoadingStateChange = { [weak self] isLoading in
            self?.signupButton.isLoading = isLoading
        }

        viewModel.onSignupSuccess = { [weak self] in
            Haptics.success()
            self?.onSignupSuccess?()
        }

        viewModel.onError = { [weak self] message in
            self?.messageView.show(message, style: .error)
        }
    }
}
