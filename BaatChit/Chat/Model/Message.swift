//
//  Message.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/11/26.
//

import Foundation
import FirebaseFirestore

struct Message: Equatable {
    let id: String
    let senderId: String
    let text: String
    let imageData: Data?
    let sentAt: Date
    let isRead: Bool

    /// True until the server has saved the message.
    let isPending: Bool
}

extension Message {

    init?(
        id: String,
        dictionary: [String: Any],
        isPending: Bool
    ) {

        guard let senderId = dictionary["senderId"] as? String else {
            return nil
        }

        self.init(
            id: id,
            senderId: senderId,
            text: dictionary["text"] as? String ?? "",
            imageData: dictionary["imageData"] as? Data,
            sentAt: (dictionary["sentAt"] as? Timestamp)?.dateValue() ?? Date(),
            isRead: dictionary["isRead"] as? Bool ?? false,
            isPending: isPending
        )
    }
}
