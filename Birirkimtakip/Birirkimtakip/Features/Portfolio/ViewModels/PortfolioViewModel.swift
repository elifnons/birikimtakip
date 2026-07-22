//
//  PortfolioViewModel.swift
//  Birirkimtakip
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class PortfolioViewModel: ObservableObject {
    @Published var holdings: [Holding] = []
    @Published var prices: [AssetType: Double] = [:]
    @Published var isLoading = false

    // MARK: - Computed

    var totalValueTRY: Double {
        holdings.reduce(0) { $0 + $1.valueTRY(unitPriceTRY: unitPrice(for: $1.assetType)) }
    }

    func unitPrice(for type: AssetType) -> Double {
        prices[type] ?? (type == .tryCash ? 1 : 0)
    }

    func valueTRY(for holding: Holding) -> Double {
        holding.valueTRY(unitPriceTRY: unitPrice(for: holding.assetType))
    }

    // MARK: - Actions

    func load() async {
        isLoading = true
        defer { isLoading = false }
        // TODO: Firebase geldiğinde Firestore'dan çek.
        await refreshPrices()
    }

    func add(_ holding: Holding) async {
        holdings.append(holding)
        await refreshPrices()
        // TODO: Firestore'a yaz.
    }

    func delete(at offsets: IndexSet) {
        holdings.remove(atOffsets: offsets)
        // TODO: Firestore'dan sil.
    }

    private func refreshPrices() async {
        for type in AssetType.allCases {
            guard let comparison = type.comparisonAsset else {
                prices[type] = 1   // TL için sabit
                continue
            }
            let price = try? await PriceHistoryService.shared.unitPrice(
                for: comparison, on: .now
            )
            prices[type] = price ?? 0
        }
    }
}
