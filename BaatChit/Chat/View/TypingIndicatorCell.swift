//
//  TypingIndicatorCell.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 11/11/26.
//

import UIKit

/// A grey bubble with three bouncing dots, shown while the other person types.
final class TypingIndicatorCell: UITableViewCell {

    static let reuseIdentifier = "TypingIndicatorCell"

    // MARK: - UI Components

    private let bubbleView = BubbleView()

    private let dots: [UIView] = (0..<3).map { _ in
        let dot = UIView()
        dot.backgroundColor = .secondaryLabel
        dot.layer.cornerRadius = 4
        return dot
    }

    // MARK: - Init

    override init(
        style: UITableViewCell.CellStyle,
        reuseIdentifier: String?
    ) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Animations stop when the view leaves the screen, so restart them.
    override func didMoveToWindow() {
        super.didMoveToWindow()

        if window != nil {
            startAnimating()
        }
    }
}

private extension TypingIndicatorCell {

    func setupUI() {

        selectionStyle = .none
        backgroundColor = .clear

        bubbleView.backgroundColor = Theme.Colors.incomingBubble

        let dotsStack = UIStackView(arrangedSubviews: dots)
        dotsStack.axis = .horizontal
        dotsStack.spacing = 5

        contentView.addSubview(bubbleView)
        bubbleView.addSubview(dotsStack)

        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        dotsStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate(
            dots.flatMap {
                [
                    $0.widthAnchor.constraint(equalToConstant: 8),
                    $0.heightAnchor.constraint(equalToConstant: 8)
                ]
            } + [

                bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
                bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -1),
                bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),

                dotsStack.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 14),
                dotsStack.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -14),
                dotsStack.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 16),
                dotsStack.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -16)
            ]
        )
    }

    func startAnimating() {

        for (index, dot) in dots.enumerated() {

            dot.layer.removeAllAnimations()

            let animation = CABasicAnimation(keyPath: "transform.translation.y")
            animation.fromValue = 0
            animation.toValue = -5
            animation.duration = 0.35
            animation.autoreverses = true
            animation.repeatCount = .infinity
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animation.beginTime = CACurrentMediaTime() + Double(index) * 0.15

            dot.layer.add(animation, forKey: "bounce")
        }
    }
}
