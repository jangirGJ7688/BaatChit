//
//  SettingsCardView.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 12/11/26.
//

import UIKit

/// A rounded card of rows, like the iOS Settings app: a coloured icon,
/// a title, optional detail text and an optional chevron.
final class SettingsCardView: UIView {

    // MARK: - Properties

    private var rows: [SettingsRowButton] = []

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = Theme.Colors.card
        layer.cornerRadius = 20
        layer.borderWidth = 1
        layer.borderColor = Theme.Colors.cardBorder.cgColor
        clipsToBounds = true

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Rows

    /// Rows without an `action` are shown as plain information.
    func addRow(
        iconName: String,
        title: String,
        detail: String? = nil,
        showsChevron: Bool = false,
        tint: UIColor,
        isDestructive: Bool = false,
        action: (() -> Void)? = nil
    ) {

        if !rows.isEmpty {
            stackView.addArrangedSubview(makeSeparator())
        }

        let row = SettingsRowButton(
            iconName: iconName,
            title: title,
            detail: detail,
            showsChevron: showsChevron,
            tint: tint,
            isDestructive: isDestructive,
            action: action
        )

        rows.append(row)
        stackView.addArrangedSubview(row)
    }

    func updateDetail(
        _ detail: String?,
        atRow index: Int
    ) {

        guard rows.indices.contains(index) else { return }

        rows[index].detail = detail
    }
}

private extension SettingsCardView {

    func makeSeparator() -> UIView {

        let container = UIView()
        let line = UIView()
        line.backgroundColor = Theme.Colors.cardBorder

        container.addSubview(line)
        line.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 0.5),
            line.topAnchor.constraint(equalTo: container.topAnchor),
            line.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            line.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            line.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 60)
        ])

        return container
    }
}

/// One row of a `SettingsCardView`.
private final class SettingsRowButton: UIControl {

    // MARK: - Properties

    var detail: String? {
        get { detailLabel.text }
        set { detailLabel.text = newValue }
    }

    private let action: (() -> Void)?

    override var isHighlighted: Bool {
        didSet {
            guard action != nil else { return }

            UIView.animate(withDuration: 0.15) {
                self.backgroundColor = self.isHighlighted
                ? Theme.Colors.fieldBackground
                : .clear
            }
        }
    }

    // MARK: - UI Components

    private let detailLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.rounded(15)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()

    // MARK: - Init

    init(
        iconName: String,
        title: String,
        detail: String?,
        showsChevron: Bool,
        tint: UIColor,
        isDestructive: Bool,
        action: (() -> Void)?
    ) {
        self.action = action
        super.init(frame: .zero)

        detailLabel.text = detail

        let iconBackground = UIView()
        iconBackground.backgroundColor = tint
        iconBackground.layer.cornerRadius = 8
        iconBackground.isUserInteractionEnabled = false

        let iconView = UIImageView(
            image: UIImage(
                systemName: iconName,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            )
        )
        iconView.tintColor = .white

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Theme.Fonts.rounded(17, weight: isDestructive ? .semibold : .regular)
        titleLabel.textColor = isDestructive ? tint : .label
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let chevronView = UIImageView(
            image: UIImage(
                systemName: "chevron.right",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
            )
        )
        chevronView.tintColor = .tertiaryLabel
        chevronView.isHidden = !showsChevron

        let stackView = UIStackView(
            arrangedSubviews: [iconBackground, titleLabel, detailLabel, chevronView]
        )
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .center
        stackView.isUserInteractionEnabled = false

        iconBackground.addSubview(iconView)
        addSubview(stackView)

        [iconView, stackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([

            heightAnchor.constraint(greaterThanOrEqualToConstant: 54),

            iconBackground.widthAnchor.constraint(equalToConstant: 32),
            iconBackground.heightAnchor.constraint(equalToConstant: 32),

            iconView.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),

            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func tapped() {

        guard let action = action else { return }

        Haptics.tap()
        action()
    }
}
