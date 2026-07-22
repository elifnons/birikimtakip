//
//  Double+Currency.swift
//  Birirkimtakip
//

import Foundation

extension Double {
    func formatAsTRY() -> String {
        Formatters.tryCurrency.string(from: NSNumber(value: self)) ?? "\(self) ₺"
    }
}
