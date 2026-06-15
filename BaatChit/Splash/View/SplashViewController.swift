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

    private let logoLabel: UILabel = {
        let label = UILabel()

        label.text = "💬 BaatChit"
        label.font = .systemFont(
            ofSize: 40,
            weight: .bold
        )

        label.textAlignment = .center

        return label
    }()

    private let taglineLabel: UILabel = {
        let label = UILabel()

        label.text = "Connect Instantly"
        label.font = .systemFont(
            ofSize: 16,
            weight: .medium
        )

        label.textColor = .secondaryLabel
        label.textAlignment = .center

        return label
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(
            style: .large
        )

        indicator.startAnimating()

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
}

private extension SplashViewController {

    func setupUI() {

        view.backgroundColor = .systemBackground

        view.addSubview(logoLabel)
        view.addSubview(taglineLabel)
        view.addSubview(activityIndicator)

        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        taglineLabel.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([

            logoLabel.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            logoLabel.centerYAnchor.constraint(
                equalTo: view.centerYAnchor,
                constant: -40
            ),

            taglineLabel.topAnchor.constraint(
                equalTo: logoLabel.bottomAnchor,
                constant: 12
            ),

            taglineLabel.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            activityIndicator.topAnchor.constraint(
                equalTo: taglineLabel.bottomAnchor,
                constant: 32
            ),

            activityIndicator.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            )
        ])
    }
}

private extension SplashViewController {

    func bindViewModel() {

        viewModel.onNavigationRequired = { [weak self] destination in

            self?.onNavigationRequired?(destination)
        }
    }
}
