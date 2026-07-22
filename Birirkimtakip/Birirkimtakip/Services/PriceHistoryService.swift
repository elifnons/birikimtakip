//
//  PriceHistoryService.swift
//  Birirkimtakip
//
//  Geçmiş ve güncel fiyat verisi.
//  Öncelik: Yahoo Finance (API key gerektirmez).
//  Fallback: MockPriceData — ağ yoksa veya Yahoo yanıt vermezse.
//

import Foundation
import Combine

@MainActor
final class PriceHistoryService: ObservableObject {
    static let shared = PriceHistoryService()

    private init() {}

    private var cache: [String: Double] = [:]

    /// Gram altın için ons dönüşüm sabiti (troy ons).
    private let gramsPerTroyOunce: Double = 31.1034768

    // MARK: - Public

    func unitPrice(for asset: ComparisonAsset, on date: Date) async throws -> Double {
        let key = cacheKey(asset: asset, date: date)
        if let cached = cache[key] { return cached }

        let value: Double
        do {
            value = try await fetchFromYahoo(asset: asset, on: date)
        } catch {
            // Ağ hatası vb. — mock veriye düş, uygulama akışı kırılmasın.
            value = MockPriceData.price(for: asset, on: date)
        }
        cache[key] = value
        return value
    }

    func priceRange(
        for asset: ComparisonAsset,
        from pastDate: Date,
        to currentDate: Date = .now
    ) async throws -> (past: Double, current: Double) {
        async let past = unitPrice(for: asset, on: pastDate)
        async let current = unitPrice(for: asset, on: currentDate)
        return try await (past, current)
    }

    func clearCache() {
        cache.removeAll()
    }

    // MARK: - Historical Series (grafik için)

    struct SeriesPoint: Hashable, Identifiable {
        let date: Date
        let priceTRY: Double
        var id: Date { date }
    }

    /// Bir varlık için verilen aralıkta günlük TL fiyat serisi.
    /// Altın: XAU/USD serisi × USD/TL serisi ÷ 31.1035.
    func historicalSeries(
        for asset: ComparisonAsset,
        from: Date,
        to: Date = .now
    ) async throws -> [SeriesPoint] {
        switch asset {
        case .usd:
            let closes = try await YahooFinanceClient.shared.historicalCloses(
                symbol: "USDTRY=X", from: from, to: to
            )
            return closes.map { SeriesPoint(date: $0.date, priceTRY: $0.close) }

        case .eur:
            let closes = try await YahooFinanceClient.shared.historicalCloses(
                symbol: "EURTRY=X", from: from, to: to
            )
            return closes.map { SeriesPoint(date: $0.date, priceTRY: $0.close) }

        case .gold:
            async let xauUsd = YahooFinanceClient.shared.historicalCloses(
                symbol: "XAUUSD=X", from: from, to: to
            )
            async let usdTry = YahooFinanceClient.shared.historicalCloses(
                symbol: "USDTRY=X", from: from, to: to
            )
            let (goldSeries, usdSeries) = try await (xauUsd, usdTry)

            // Tarihe göre eşle (aynı gün her iki seride de olmalı)
            let usdMap = Dictionary(uniqueKeysWithValues:
                usdSeries.map { (Calendar.current.startOfDay(for: $0.date), $0.close) }
            )

            return goldSeries.compactMap { g in
                let day = Calendar.current.startOfDay(for: g.date)
                guard let usdRate = usdMap[day] else { return nil }
                let gramTRY = (g.close * usdRate) / gramsPerTroyOunce
                return SeriesPoint(date: g.date, priceTRY: gramTRY)
            }

        default:
            return []
        }
    }

    // MARK: - Private

    private func fetchFromYahoo(asset: ComparisonAsset, on date: Date) async throws -> Double {
        switch asset {
        case .usd:
            return try await YahooFinanceClient.shared.closePrice(
                symbol: "USDTRY=X", on: date
            )
        case .eur:
            return try await YahooFinanceClient.shared.closePrice(
                symbol: "EURTRY=X", on: date
            )
        case .gold:
            // Gram altın TL = (ons altın USD × USD/TL) ÷ 31.1035
            async let xauUsd  = YahooFinanceClient.shared.closePrice(symbol: "XAUUSD=X", on: date)
            async let usdTry  = YahooFinanceClient.shared.closePrice(symbol: "USDTRY=X", on: date)
            let (ounceUsd, usdRate) = try await (xauUsd, usdTry)
            return (ounceUsd * usdRate) / gramsPerTroyOunce
        default:
            return 0
        }
    }

    private func cacheKey(asset: ComparisonAsset, date: Date) -> String {
        let day = ISO8601DateFormatter.string(
            from: date,
            timeZone: .current,
            formatOptions: [.withYear, .withMonth, .withDay, .withDashSeparatorInDate]
        )
        return "\(asset.rawValue)_\(day)"
    }
}

// MARK: - Mock veri (Yahoo cevap vermezse yedek)

enum MockPriceData {
    private static let currentPrices: [ComparisonAsset: Double] = [
        .gold: 4_850.0,
        .usd:  40.20,
        .eur:  43.80
    ]

    private static let assumedAnnualReturn: [ComparisonAsset: Double] = [
        .gold: 0.65,
        .usd:  0.40,
        .eur:  0.35
    ]

    static func price(for asset: ComparisonAsset, on date: Date) -> Double {
        let current = currentPrices[asset] ?? 1
        let annualReturn = assumedAnnualReturn[asset] ?? 0

        let daysAgo = Calendar.current.dateComponents([.day], from: date, to: .now).day ?? 0
        if daysAgo <= 0 { return current }

        let years = Double(daysAgo) / 365.0
        let factor = pow(1 + annualReturn, years)
        return current / factor
    }
}
