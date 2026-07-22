//
//  BankRateService.swift
//  Birirkimtakip
//
//  Türk bankaları için tipik faiz oranları ve getiri hesabı.
//  MVP: sabit yaklaşık oranlar. Sonra: HesapKurdu / BDDK verisi.
//

import Foundation
import Combine
@MainActor
final class BankRateService: ObservableObject {
    static let shared = BankRateService()

    private init() {}

    /// Yıllık yaklaşık oranlar (2026 ortalaması varsayımı).
    /// Gerçek entegrasyona geçince buradan JSON/API'a taşınacak.
    var dailyAnnualRate: Double   = 0.42   // %42
    var monthlyAnnualRate: Double = 0.48   // %48

    /// Verilen tutarın, belirtilen gün boyunca faizde net getirisi.
    /// - Parameter compoundingDays: 1 = günlük bileşik, 30 = aylık bileşik.
    /// - Stopaj: TL mevduat için basitleştirilmiş oranlar.
    func projectedValue(
        amount: Double,
        days: Int,
        annualRate: Double,
        compoundingDays: Int
    ) -> Double {
        guard amount > 0, days > 0 else { return amount }

        // Bileşik faiz: (1 + r * dönem/365)^(dönem sayısı)
        let periodRate = annualRate * Double(compoundingDays) / 365.0
        let periodsCount = Double(days) / Double(compoundingDays)
        let gross = amount * pow(1 + periodRate, periodsCount)
        let grossInterest = gross - amount

        // Stopaj: 6 ay altı %5, 6-12 ay %3, 12 ay üstü %0 (basitleştirilmiş).
        let stopajRate: Double
        switch days {
        case ...180:        stopajRate = 0.05
        case 181...365:     stopajRate = 0.03
        default:            stopajRate = 0.0
        }

        let netInterest = grossInterest * (1 - stopajRate)
        return amount + netInterest
    }

    /// Seçilen banka ürünü için nihai değer.
    func projectedValue(for asset: ComparisonAsset, amount: Double, days: Int) -> Double {
        switch asset {
        case .bankDaily:
            return projectedValue(
                amount: amount,
                days: days,
                annualRate: dailyAnnualRate,
                compoundingDays: 1
            )
        case .bankMonthly:
            return projectedValue(
                amount: amount,
                days: days,
                annualRate: monthlyAnnualRate,
                compoundingDays: 32   // Türkiye'de tipik minimum vade
            )
        default:
            return amount
        }
    }
}
