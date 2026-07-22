//
//  Formatters.swift
//  Birirkimtakip
//

import Foundation

enum Formatters {
    static let tryCurrency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "TRY"
        f.locale = Locale(identifier: "tr_TR")
        f.maximumFractionDigits = 2
        return f
    }()

    static let percent: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.maximumFractionDigits = 2
        f.locale = Locale(identifier: "tr_TR")
        return f
    }()

    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
}
