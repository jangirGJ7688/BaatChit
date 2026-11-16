//
//  ProfileViewController.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/11/26.
//

import UIKit
import PhotosUI

final class ProfileViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: ProfileViewModel

    var onLogout: (() -> Void)?

    private var hasAnimatedIn = false

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()

    private let headerView: GradientView = {
        let view = GradientView()
        view.layer.cornerRadius = Theme.Radius.large
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        view.clipsToBounds = true
        return view
    }()

    private let backButton: UIButton = {
        let button = UIButton(type: .system)

        button.setImage(
            UIImage(
                systemName: "chevron.left",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
            ),
            for: .normal
        )

        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.layer.cornerRadius = 20

        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Profile"
        label.font = Theme.Fonts.rounded(17, weight: .semibold)
        label.textColor = .white
        return label
    }()

    /// White ring around the photo.
    private let avatarRing: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.Colors.background
        view.layer.cornerRadius = 62
        view.layer.shadowColor = Theme.Colors.gradientStart.cgColor
        view.layer.shadowOpacity = 0.6
        view.layer.shadowRadius = 18
        view.layer.shadowOffset = .zero
        return view
    }()

    private let avatarView = AvatarView()

    private let cameraButton: UIButton = {
        let button = UIButton(type: .system)

        button.setImage(
            UIImage(
                systemName: "camera.fill",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            ),
            for: .normal
        )

        button.tintColor = .white
        button.backgroundColor = Theme.Colors.brand
        button.layer.cornerRadius = 18
        button.layer.borderWidth = 3
        button.layer.borderColor = Theme.Colors.background.cgColor

        return button
    }()

    private let photoActivityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = Theme.Fonts.rounded(26, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.rounded(16)
        label.textColor = Theme.Colors.secondaryText
        label.textAlignment = .center
        return label
    }()

    private let accountCard = SettingsCardView()
    private let actionsCard = SettingsCardView()

    // MARK: - Init

    init(viewModel: ProfileViewModel = ProfileViewModel()) {
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

        viewModel.startListening()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // This screen draws its own header instead of the navigation bar.
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !hasAnimatedIn else { return }

        hasAnimatedIn = true
        UIView.animateEntrance(of: [nameLabel, emailLabel, accountCard, actionsCard])
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
}

// MARK: - Setup UI

private extension ProfileViewController {

    func setupUI() {

        view.backgroundColor = Theme.Colors.groupedBackground

        view.addSubview(scrollView)

        [headerView, avatarRing, cameraButton, nameLabel, emailLabel, accountCard, actionsCard].forEach {
            scrollView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        [backButton, titleLabel].forEach {
            headerView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        [avatarView, photoActivityIndicator].forEach {
            avatarRing.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        scrollView.translatesAutoresizingMaskIntoConstraints = false

        accountCard.addRow(
            iconName: "envelope.fill",
            title: "Email",
            tint: Theme.Colors.brand
        )

        accountCard.addRow(
            iconName: "photo.fill",
            title: "Change profile photo",
            showsChevron: true,
            tint: .systemPink
        ) { [weak self] in
            self?.showPhotoPicker()
        }

        actionsCard.addRow(
            iconName: "rectangle.portrait.and.arrow.right",
            title: "Log Out",
            tint: Theme.Colors.error,
            isDestructive: true
        ) { [weak self] in
            self?.confirmLogout()
        }

        let content = scrollView.contentLayoutGuide
        let safeArea = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            headerView.topAnchor.constraint(equalTo: content.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            headerView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            headerView.bottomAnchor.constraint(equalTo: safeArea.topAnchor, constant: 130),

            backButton.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),

            // The photo overlaps the bottom edge of the header.
            avatarRing.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            avatarRing.centerYAnchor.constraint(equalTo: headerView.bottomAnchor),
            avatarRing.widthAnchor.constraint(equalToConstant: 124),
            avatarRing.heightAnchor.constraint(equalToConstant: 124),

            avatarView.centerXAnchor.constraint(equalTo: avatarRing.centerXAnchor),
            avatarView.centerYAnchor.constraint(equalTo: avatarRing.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 116),
            avatarView.heightAnchor.constraint(equalToConstant: 116),

            photoActivityIndicator.centerXAnchor.constraint(equalTo: avatarRing.centerXAnchor),
            photoActivityIndicator.centerYAnchor.constraint(equalTo: avatarRing.centerYAnchor),

            cameraButton.trailingAnchor.constraint(equalTo: avatarRing.trailingAnchor, constant: -2),
            cameraButton.bottomAnchor.constraint(equalTo: avatarRing.bottomAnchor, constant: -2),
            cameraButton.widthAnchor.constraint(equalToConstant: 36),
            cameraButton.heightAnchor.constraint(equalToConstant: 36),

            nameLabel.topAnchor.constraint(equalTo: avatarRing.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            nameLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),

            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            emailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            emailLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            accountCard.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 28),
            accountCard.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            accountCard.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),

            actionsCard.topAnchor.constraint(equalTo: accountCard.bottomAnchor, constant: 20),
            actionsCard.leadingAnchor.constraint(equalTo: accountCard.leadingAnchor),
            actionsCard.trailingAnchor.constraint(equalTo: accountCard.trailingAnchor),
            actionsCard.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -32)
        ])
    }
}

// MARK: - Actions

private extension ProfileViewController {

    func setupActions() {

        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        cameraButton.addTarget(self, action: #selector(cameraTapped), for: .touchUpInside)
    }

    @objc
    func backTapped() {
        Haptics.tap()
        navigationController?.popViewController(animated: true)
    }

    @objc
    func cameraTapped() {
        Haptics.tap()
        showPhotoPicker()
    }

    func showPhotoPicker() {

        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self

        present(picker, animated: true)
    }

    /// Logging out is easy to hit by accident, so ask first.
    func confirmLogout() {

        let sheet = UIAlertController(
            title: "Log out of BaatChit?",
            message: nil,
            preferredStyle: .actionSheet
        )

        sheet.addAction(
            UIAlertAction(title: "Log Out", style: .destructive) { [weak self] _ in
                self?.viewModel.logout()
            }
        )

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(sheet, animated: true)
    }
}

// MARK: - ViewModel Binding

private extension ProfileViewController {

    func bindViewModel() {

        viewModel.onUserUpdated = { [weak self] in

            guard let self = self,
                  let user = self.viewModel.user else { return }

            self.avatarView.configure(with: user, showsOnlineStatus: false)
            self.nameLabel.text = user.displayName
            self.emailLabel.text = user.email
            self.accountCard.updateDetail(user.email, atRow: 0)
        }

        viewModel.onLoadingStateChange = { [weak self] isLoading in

            if isLoading {
                self?.photoActivityIndicator.startAnimating()
            } else {
                self?.photoActivityIndicator.stopAnimating()
            }

            self?.avatarView.alpha = isLoading ? 0.5 : 1
            self?.view.isUserInteractionEnabled = !isLoading
        }

        viewModel.onLogout = { [weak self] in
            self?.onLogout?()
        }

        viewModel.onError = { [weak self] message in
            self?.showErrorAlert(message)
        }
    }
}

// MARK: - PHPickerViewControllerDelegate

extension ProfileViewController: PHPickerViewControllerDelegate {

    func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {

        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else {
            return
        }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in

            guard let image = object as? UIImage else { return }

            DispatchQueue.main.async {
                self?.viewModel.uploadPhoto(image)
            }
        }
    }
}
