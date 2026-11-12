//
//  AuthTextField.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/11/26.
//

import UIKit

enum AuthTextField {

    static func make(
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
