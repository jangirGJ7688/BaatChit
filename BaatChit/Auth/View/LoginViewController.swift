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

    // MARK: - UI Components

    private let scrollView = UIScrollView()

    private let contentView = UIView()

    private let logoLabel: UILabel = {
        let label = UILabel()
        label.text = "💬 BaatChit"
        label.font = .systemFont(ofSize: 36, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome Back"
        label.font = .systemFont(ofSize: 30, weight: .bold)
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Login to continue chatting"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var emailTextField = createTextField(
        placeholder: "Email Address",
        imageName: "envelope"
    )

    private lazy var passwordTextField = createTextField(
        placeholder: "Password",
        imageName: "lock"
    )

    private let forgotPasswordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Forgot Password?", for: .normal)
        button.contentHorizontalAlignment = .right
        return button
    }()

    private let loginButton: UIButton = {
        let button = UIButton(type: .system)

        button.setTitle("Login", for: .normal)
        button.setTitleColor(.white, for: .normal)

        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 14

        button.titleLabel?.font = .boldSystemFont(ofSize: 18)

        button.layer.shadowColor = UIColor.systemBlue.cgColor
        button.layer.shadowOpacity = 0.25
        button.layer.shadowOffset = CGSize(width: 0, height: 5)
        button.layer.shadowRadius = 8

        return button
    }()

    private let signupButton: UIButton = {
        let button = UIButton(type: .system)

        let attributedText = NSMutableAttributedString(
            string: "Don't have an account? ",
            attributes: [
                .foregroundColor: UIColor.secondaryLabel
            ]
        )

        attributedText.append(
            NSAttributedString(
                string: "Sign Up",
                attributes: [
                    .foregroundColor: UIColor.systemBlue,
                    .font: UIFont.boldSystemFont(ofSize: 16)
                ]
            )
        )

        button.setAttributedTitle(attributedText, for: .normal)

        return button
    }()

    private let activityIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - Init

    init(viewModel: LoginViewModel = LoginViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

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
}

// MARK: - Setup UI

private extension LoginViewController {

    func setupUI() {

        view.backgroundColor = .systemBackground

        passwordTextField.isSecureTextEntry = true

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [
            logoLabel,
            titleLabel,
            subtitleLabel,
            emailTextField,
            passwordTextField,
            forgotPasswordButton,
            loginButton,
            signupButton,
            activityIndicator
        ].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            logoLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 80),
            logoLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            titleLabel.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 50),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            emailTextField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            emailTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            emailTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            emailTextField.heightAnchor.constraint(equalToConstant: 56),

            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 16),
            passwordTextField.leadingAnchor.constraint(equalTo: emailTextField.leadingAnchor),
            passwordTextField.trailingAnchor.constraint(equalTo: emailTextField.trailingAnchor),
            passwordTextField.heightAnchor.constraint(equalToConstant: 56),

            forgotPasswordButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 12),
            forgotPasswordButton.trailingAnchor.constraint(equalTo: passwordTextField.trailingAnchor),

            loginButton.topAnchor.constraint(equalTo: forgotPasswordButton.bottomAnchor, constant: 24),
            loginButton.leadingAnchor.constraint(equalTo: emailTextField.leadingAnchor),
            loginButton.trailingAnchor.constraint(equalTo: emailTextField.trailingAnchor),
            loginButton.heightAnchor.constraint(equalToConstant: 56),

            signupButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 24),
            signupButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            signupButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func createTextField(
        placeholder: String,
        imageName: String
    ) -> UITextField {

        let textField = UITextField()

        textField.placeholder = placeholder
        textField.backgroundColor = .secondarySystemBackground
        textField.layer.cornerRadius = 14
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemGray5.cgColor
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no

        let icon = UIImageView(
            image: UIImage(systemName: imageName)
        )

        icon.tintColor = .secondaryLabel
        icon.frame = CGRect(x: 12, y: 0, width: 20, height: 20)

        let container = UIView(
            frame: CGRect(x: 0, y: 0, width: 44, height: 20)
        )

        container.addSubview(icon)

        textField.leftView = container
        textField.leftViewMode = .always

        return textField
    }
}

// MARK: - Actions

private extension LoginViewController {

    func setupActions() {

        loginButton.addTarget(
            self,
            action: #selector(loginTapped),
            for: .touchUpInside
        )

        signupButton.addTarget(
            self,
            action: #selector(signupTapped),
            for: .touchUpInside
        )

        forgotPasswordButton.addTarget(
            self,
            action: #selector(forgotPasswordTapped),
            for: .touchUpInside
        )
    }

    @objc
    func loginTapped() {

        viewModel.login(
            email: emailTextField.text,
            password: passwordTextField.text
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

            if isLoading {
                self?.activityIndicator.startAnimating()
                self?.loginButton.isEnabled = false
            } else {
                self?.activityIndicator.stopAnimating()
                self?.loginButton.isEnabled = true
            }
        }

        viewModel.onLoginSuccess = { [weak self] in
            self?.onLoginSuccess?()
        }

        viewModel.onError = { [weak self] message in

            let alert = UIAlertController(
                title: "Error",
                message: message,
                preferredStyle: .alert
            )

            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default
                )
            )

            self?.present(alert, animated: true)
        }
    }
}
