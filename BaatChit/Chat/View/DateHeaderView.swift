//
//  DateHeaderView.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 11/11/26.
//

import UIKit

/// The "Today" / "Yesterday" pill above each day's messages.
final class DateHeaderView: UITableViewHeaderFooterView {

    static let reuseIdentifier = "DateHeaderView"

    // MARK: - UI Components

    private let pillView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.Colors.incomingBubble.withAlphaComponent(0.9)
        view.layer.cornerRadius = 10
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.rounded(12, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()

    // MARK: - Init

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure

    func configure(title: String) {
        titleLabel.text = title
    }
}

private extension DateHeaderView {

    func setupUI() {

        backgroundConfiguration = .clear()

        contentView.addSubview(pillView)
        pillView.addSubview(titleLabel)

        pillView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([

            pillView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            pillView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            pillView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            titleLabel.topAnchor.constraint(equalTo: pillView.topAnchor, constant: 4),
            titleLabel.bottomAnchor.constraint(equalTo: pillView.bottomAnchor, constant: -4),
            titleLabel.leadingAnchor.constraint(equalTo: pillView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: pillView.trailingAnchor, constant: -10)
        ])
    }
}
