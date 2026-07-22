//
//  CompareResult.swift
//  Birirkimtakip
//
//  Bir seçenek için karşılaştırma sonucu.
//  Banka faizi ve fiziksel varlık (altın/döviz) aynı yapıya oturur.
//

import Foundation

struct CompareResult: Identifiable, Hashable {
    let asset: ComparisonAsset
    let amountInvestedTRY: Double
    let currentValueTRY: Double

    // Fiziksel varlıklar için (banka'da 0).
    let unitsBought: Double
    let pastUnitPrice: Double
    let currentUnitPrice: Double

    var id: String { asset.id }

    var profitTRY: Double { currentValueTRY - amountInvestedTRY }

    var profitPercent: Double {
        guard amountInvestedTRY > 0 else { return 0 }
        return (profitTRY / amountInvestedTRY) * 100
    }

    // MARK: - Fabrika metotları

    /// Altın / USD / EUR — geçmiş-şimdi fiyat farkına göre.
    static func fromPriceChange(
        asset: ComparisonAsset,
        amountTRY: Double,
        pastPrice: Double,
        currentPrice: Double
    ) -> CompareResult {
        let units = pastPrice > 0 ? amountTRY / pastPrice : 0
        return CompareResult(
            asset: asset,
            amountInvestedTRY: amountTRY,
            currentValueTRY: units * currentPrice,
            unitsBought: units,
            pastUnitPrice: pastPrice,
            currentUnitPrice: currentPrice
        )
    }

    /// Banka mevduatı — projeksiyon üzerinden.
    static func fromBank(
        asset: ComparisonAsset,
        amountTRY: Double,
        projectedValue: Double
    ) -> CompareResult {
        CompareResult(
            asset: asset,
            amountInvestedTRY: amountTRY,
            currentValueTRY: projectedValue,
            unitsBought: 0,
            pastUnitPrice: 0,
            currentUnitPrice: 0
        )
    }
}
