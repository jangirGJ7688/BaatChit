//
//  SplashViewController.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/06/26.
//

import UIKit

final class SplashViewController: UIViewController {

    // MARK: - Properties

    private let viewModel = SplashViewModel()

    var onNavigationRequired: ((SplashViewModel.Destination) -> Void)?

    // MARK: - UI Components

    /// Fades in behind the logo; the launch screen is plain navy.
    private let backgroundView = AuroraBackgroundView()

    /// Same size and spot as the logo on LaunchScreen.storyboard, so the
    /// launch screen hands over to this one without a jump.
    private let logoView = LogoBadgeView(size: 120)

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "BaatChit"
        label.font = Theme.Fonts.rounded(40, weight: .heavy)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private let taglineLabel: UILabel = {
        let label = UILabel()
        label.text = "Connect instantly"
        label.font = Theme.Fonts.rounded(17, weight: .medium)
        label.textColor = Theme.Colors.secondaryText
        label.textAlignment = .center
        return label
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = Theme.Colors.secondaryText
        return indicator
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        bindViewModel()

        viewModel.checkAuthenticationStatus()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(
            true,
            animated: false
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        animateLogo()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
}

private extension SplashViewController {

    func setupUI() {

        view.backgroundColor = Theme.Colors.background

        [backgroundView, logoView, titleLabel, taglineLabel, activityIndicator].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([

            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Matches LaunchScreen.storyboard.
            logoView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),

            titleLabel.topAnchor.constraint(equalTo: logoView.bottomAnchor, constant: 28),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            taglineLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            taglineLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -40
            )
        ])

        // The launch screen shows only the logo; the rest comes in after.
        backgroundView.alpha = 0
        logoView.layer.shadowOpacity = 0
        titleLabel.alpha = 0
        taglineLabel.alpha = 0
    }

    func animateLogo() {

        UIView.animate(withDuration: 0.8) {
            self.backgroundView.alpha = 1
        }

        // The glow behind the logo brightens.
        let glow = CABasicAnimation(keyPath: "shadowOpacity")
        glow.fromValue = 0
        glow.toValue = 0.55
        glow.duration = 0.6
        logoView.layer.shadowOpacity = 0.55
        logoView.layer.add(glow, forKey: "glow")

        // A small "pop", like a message arriving.
        UIView.animateKeyframes(withDuration: 0.6, delay: 0.05) {

            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.4) {
                self.logoView.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
            }

            UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.6) {
                self.logoView.transform = .identity
            }
        }

        UIView.animateEntrance(of: [titleLabel, taglineLabel], delay: 0.2)

        activityIndicator.startAnimating()
    }

    func bindViewModel() {

        viewModel.onNavigationRequired = { [weak self] destination in

            self?.onNavigationRequired?(destination)
        }
    }
}
