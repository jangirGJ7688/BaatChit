//
//  Date+Chat.swift
//  BaatChit
//
//  Created by Ganpat Jangir on 10/11/26.
//

import Foundation

extension Date {

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    private static let dayMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        return formatter
    }()

    private static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE")
        return formatter
    }()

    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d MMM yyyy")
        return formatter
    }()

    /// "2026-11-11" — the same for every time on one day.
    var dayKey: String {
        Date.dayKeyFormatter.string(from: self)
    }

    /// "Today", "Yesterday", "Monday", "8 Nov" or "8 Nov 2025"
    var daySectionTitle: String {

        let calendar = Calendar.current

        if calendar.isDateInToday(self) {
            return "Today"
        }

        if calendar.isDateInYesterday(self) {
            return "Yesterday"
        }

        let daysAgo = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: self),
            to: calendar.startOfDay(for: Date())
        ).day ?? 0

        if daysAgo < 7 {
            return Date.weekdayFormatter.string(from: self)
        }

        if calendar.isDate(self, equalTo: Date(), toGranularity: .year) {
            return Date.dayMonthFormatter.string(from: self)
        }

        return Date.fullDateFormatter.string(from: self)
    }

    /// "5:30 PM"
    var messageTimeText: String {
        Date.timeFormatter.string(from: self)
    }

    /// "5:30 PM", "Yesterday" or "10/11/26"
    var chatListText: String {

        let calendar = Calendar.current

        if calendar.isDateInToday(self) {
            return messageTimeText
        }

        if calendar.isDateInYesterday(self) {
            return "Yesterday"
        }

        return Date.shortDateFormatter.string(from: self)
    }

    /// "today at 5:30 PM", "yesterday at 5:30 PM" or "8 Nov at 5:30 PM"
    var lastSeenText: String {

        let calendar = Calendar.current

        if calendar.isDateInToday(self) {
            return "today at \(messageTimeText)"
        }

        if calendar.isDateInYesterday(self) {
            return "yesterday at \(messageTimeText)"
        }

        return "\(Date.dayMonthFormatter.string(from: self)) at \(messageTimeText)"
    }
}
