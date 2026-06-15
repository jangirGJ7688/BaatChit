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

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Create Account"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Join BaatChit today"
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var nameTextField = createTextField(
        placeholder: "Full Name",
        imageName: "person"
    )

    private lazy var emailTextField = createTextField(
        placeholder: "Email Address",
        imageName: "envelope"
    )

    private lazy var passwordTextField = createTextField(
        placeholder: "Password",
        imageName: "lock"
    )

    private lazy var confirmPasswordTextField = createTextField(
        placeholder: "Confirm Password",
        imageName: "lock"
    )

    private let signupButton: UIButton = {
        let button = UIButton(type: .system)

        button.setTitle("Create Account", for: .normal)
        button.setTitleColor(.white, for: .normal)

        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 14

        button.titleLabel?.font = .boldSystemFont(ofSize: 18)

        return button
    }()

    private let loginButton: UIButton = {
        let button = UIButton(type: .system)

        let attributed = NSMutableAttributedString(
            string: "Already have an account? ",
            attributes: [
                .foregroundColor: UIColor.secondaryLabel
            ]
        )

        attributed.append(
            NSAttributedString(
                string: "Login",
                attributes: [
                    .foregroundColor: UIColor.systemBlue,
                    .font: UIFont.boldSystemFont(ofSize: 16)
                ]
            )
        )

        button.setAttributedTitle(attributed, for: .normal)

        return button
    }()

    private let activityIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - Init

    init(viewModel: SignupViewModel = SignupViewModel()) {
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
}

private extension SignupViewController {

    func setupUI() {

        view.backgroundColor = .systemBackground

        passwordTextField.isSecureTextEntry = true
        confirmPasswordTextField.isSecureTextEntry = true

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [
            titleLabel,
            subtitleLabel,
            nameTextField,
            emailTextField,
            passwordTextField,
            confirmPasswordTextField,
            signupButton,
            loginButton,
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

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 80),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            nameTextField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            nameTextField.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            nameTextField.heightAnchor.constraint(equalToConstant: 56),

            emailTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 16),
            emailTextField.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            emailTextField.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            emailTextField.heightAnchor.constraint(equalToConstant: 56),

            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 16),
            passwordTextField.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            passwordTextField.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            passwordTextField.heightAnchor.constraint(equalToConstant: 56),

            confirmPasswordTextField.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 16),
            confirmPasswordTextField.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            confirmPasswordTextField.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            confirmPasswordTextField.heightAnchor.constraint(equalToConstant: 56),

            signupButton.topAnchor.constraint(equalTo: confirmPasswordTextField.bottomAnchor, constant: 30),
            signupButton.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            signupButton.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            signupButton.heightAnchor.constraint(equalToConstant: 56),

            loginButton.topAnchor.constraint(equalTo: signupButton.bottomAnchor, constant: 24),
            loginButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loginButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

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

private extension SignupViewController {

    func setupActions() {

        signupButton.addTarget(
            self,
            action: #selector(signupTapped),
            for: .touchUpInside
        )

        loginButton.addTarget(
            self,
            action: #selector(loginTapped),
            for: .touchUpInside
        )
    }

    @objc
    func signupTapped() {

        viewModel.signup(
            name: nameTextField.text,
            email: emailTextField.text,
            password: passwordTextField.text,
            confirmPassword: confirmPasswordTextField.text
        )
    }

    @objc
    func loginTapped() {

        onLoginTapped?()
    }

    func bindViewModel() {

        viewModel.onLoadingStateChange = { [weak self] loading in

            loading
            ? self?.activityIndicator.startAnimating()
            : self?.activityIndicator.stopAnimating()
        }

        viewModel.onSignupSuccess = { [weak self] in
            self?.onSignupSuccess?()
        }

        viewModel.onError = { [weak self] message in

            let alert = UIAlertController(
                title: "Error",
                message: message,
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "OK", style: .default))

            self?.present(alert, animated: true)
        }
    }
}
