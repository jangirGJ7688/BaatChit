//
//  Validator.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/11/26.
//

import Foundation

enum Validator {

    static func isValidEmail(_ email: String) -> Bool {

        let regex =
        "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"

        return NSPredicate(
            format: "SELF MATCHES %@",
            regex
        ).evaluate(with: email)
    }
}
