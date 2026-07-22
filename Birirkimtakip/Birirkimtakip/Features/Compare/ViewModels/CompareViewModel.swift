//
//  CompareViewModel.swift
//  Birirkimtakip
//

import Foundation
import Combine

@MainActor
final class CompareViewModel: ObservableObject {
    @Published var scenario: CompareScenario = .default
    @Published var results: [CompareResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var winner: CompareResult? {
        results.max(by: { $0.profitPercent < $1.profitPercent })
    }

    var rankedResults: [CompareResult] {
        results.sorted(by: { $0.profitPercent > $1.profitPercent })
    }

    func run() async {
        guard scenario.amountTRY > 0 else {
            results = []
            return
        }
        isLoading = true
        defer { isLoading = false }

        let pastDate = scenario.period.referenceDate()
        var computed: [CompareResult] = []

        for asset in scenario.assets {
            do {
                if asset.isBankProduct {
                    let projected = BankRateService.shared.projectedValue(
                        for: asset,
                        amount: scenario.amountTRY,
                        days: scenario.period.days
                    )
                    computed.append(
                        .fromBank(
                            asset: asset,
                            amountTRY: scenario.amountTRY,
                            projectedValue: projected
                        )
                    )
                } else {
                    let range = try await PriceHistoryService.shared.priceRange(
                        for: asset,
                        from: pastDate
                    )
                    computed.append(
                        .fromPriceChange(
                            asset: asset,
                            amountTRY: scenario.amountTRY,
                            pastPrice: range.past,
                            currentPrice: range.current
                        )
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        results = computed
    }
}
