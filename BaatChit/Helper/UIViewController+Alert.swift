//
//  UIViewController+Alert.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/11/26.
//

import UIKit

extension UIViewController {

    /// Shows an error alert without it being silently dropped: it's
    /// presented from whatever is on top, and retried if the screen is
    /// still animating in. Also printed to the Xcode console.
    func showErrorAlert(
        _ message: String,
        retriesLeft: Int = 5
    ) {

        print("⚠️ [\(type(of: self))] \(message)")

        var presenter: UIViewController = self

        while let presented = presenter.presentedViewController {
            presenter = presented
        }

        let isReady = presenter.viewIfLoaded?.window != nil
        && !presenter.isBeingPresented
        && !presenter.isBeingDismissed
        && presenter.transitionCoordinator == nil

        guard isReady else {

            guard retriesLeft > 0 else { return }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showErrorAlert(message, retriesLeft: retriesLeft - 1)
            }

            return
        }

        // Don't stack a second alert on top of one that's already showing.
        guard !(presenter is UIAlertController) else { return }

        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))

        presenter.present(alert, animated: true)
    }
}
