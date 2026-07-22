//
//  AddHoldingViewModel.swift
//  Birirkimtakip
//

import Foundation
import Combine

@MainActor
final class AddHoldingViewModel: ObservableObject {
    @Published var assetType: AssetType = .tryCash
    @Published var amount: Double = 0
    @Published var note: String = ""

    var isValid: Bool {
        amount > 0
    }

    func buildHolding() -> Holding? {
        guard isValid else { return nil }
        return Holding(
            id: UUID().uuidString,
            assetType: assetType,
            amount: amount,
            note: note.trimmingCharacters(in: .whitespaces).isEmpty ? nil : note
        )
    }
}
