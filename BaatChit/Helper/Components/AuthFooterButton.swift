//
//  AuthFooterButton.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/11/26.
//

import UIKit

/// "Don't have an account? **Sign Up**" style link under a form.
final class AuthFooterButton: UIButton {

    init(
        question: String,
        action: String
    ) {
        super.init(frame: .zero)

        let title = NSMutableAttributedString(
            string: "\(question) ",
            attributes: [
                .foregroundColor: UIColor.secondaryLabel,
                .font: Theme.Fonts.rounded(15, weight: .medium)
            ]
        )

        title.append(
            NSAttributedString(
                string: action,
                attributes: [
                    .foregroundColor: Theme.Colors.brand,
                    .font: Theme.Fonts.rounded(15, weight: .bold)
                ]
            )
        )

        setAttributedTitle(title, for: .normal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.5 : 1
        }
    }
}
