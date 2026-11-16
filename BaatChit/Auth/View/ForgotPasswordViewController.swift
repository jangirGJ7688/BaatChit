//
//  ForgotPasswordViewController.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/06/26.
//

import UIKit

final class ForgotPasswordViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: ForgotPasswordViewModel

    var onBackToLogin: (() -> Void)?

    private var hasAnimatedIn = false
    private var hasSentLink = false

    // MARK: - UI Components

    private let formView = AuthFormView(
        headerView: AuthHeaderView(
            title: "Forgot password?",
            subtitle: "Enter your email and we'll send you a link to reset it.",
            showsBackButton: true
        )
    )

    private let emailField = FormField(
        placeholder: "Email address",
        iconName: "envelope.fill",
        kind: .email
    )

    private let messageView = InlineMessageView()

    private let resetButton = PrimaryButton(title: "Send Reset Link")

    private let backButton = AuthFooterButton(
        question: "Remembered it?",
        action: "Log In"
    )

    // MARK: - Init

    init(
        viewModel: ForgotPasswordViewModel = ForgotPasswordViewModel()
    ) {
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

private extension ForgotPasswordViewController {

    func setupUI() {

        emailField.returnKeyType = .send

        [emailField, messageView, resetButton, backButton].forEach {
            formView.formStack.addArrangedSubview($0)
        }

        formView.formStack.setCustomSpacing(20, after: emailField)
        formView.formStack.setCustomSpacing(20, after: messageView)
        formView.formStack.setCustomSpacing(24, after: resetButton)
    }
}

// MARK: - Actions

private extension ForgotPasswordViewController {

    func setupActions() {

        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

        formView.headerView.onBack = { [weak self] in
            self?.onBackToLogin?()
        }

        emailField.onReturn = { [weak self] in
            self?.resetTapped()
        }

        emailField.onTextChange = { [weak self] in
            self?.messageView.hide()
        }
    }

    @objc
    func resetTapped() {

        // After the link is sent, the button takes you back to login.
        guard !hasSentLink else {
            onBackToLogin?()
            return
        }

        view.endEditing(true)

        viewModel.resetPassword(email: emailField.text)
    }

    @objc
    func backTapped() {
        onBackToLogin?()
    }
}

// MARK: - ViewModel Binding

private extension ForgotPasswordViewController {

    func bindViewModel() {

        viewModel.onLoadingStateChange = { [weak self] isLoading in
            self?.resetButton.isLoading = isLoading
        }

        viewModel.onSuccess = { [weak self] message in

            guard let self = self else { return }

            self.hasSentLink = true
            self.messageView.show(message, style: .success)
            self.resetButton.setTitle("Back to Log In", for: .normal)
            self.backButton.isHidden = true
        }

        viewModel.onError = { [weak self] message in
            self?.messageView.show(message, style: .error)
        }
    }
}
