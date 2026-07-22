//
//  CompareScenario.swift
//  Birirkimtakip
//
//  "X TL'yi Y süre önce koysaydım" senaryosu.
//

import Foundation

enum ComparePeriod: String, Codable, CaseIterable, Identifiable {
    case oneMonth   = "1A"
    case threeMonth = "3A"
    case sixMonth   = "6A"
    case oneYear    = "1Y"
    case threeYear  = "3Y"
    case fiveYear   = "5Y"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oneMonth:   return "1 Ay"
        case .threeMonth: return "3 Ay"
        case .sixMonth:   return "6 Ay"
        case .oneYear:    return "1 Yıl"
        case .threeYear:  return "3 Yıl"
        case .fiveYear:   return "5 Yıl"
        }
    }

    /// Bugünden geriye kaç gün gidileceği (kaba yaklaşım — takvim ay/yıl için Calendar kullan).
    var days: Int {
        switch self {
        case .oneMonth:   return 30
        case .threeMonth: return 90
        case .sixMonth:   return 180
        case .oneYear:    return 365
        case .threeYear:  return 365 * 3
        case .fiveYear:   return 365 * 5
        }
    }

    /// Referans (geçmiş) tarihi verilen "bugün"e göre hesaplar.
    func referenceDate(from today: Date = .now) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: today) ?? today
    }
}

struct CompareScenario: Codable, Hashable {
    var amountTRY: Double
    var period: ComparePeriod
    var assets: [ComparisonAsset]

    static let `default` = CompareScenario(
        amountTRY: 10_000,
        period: .sixMonth,
        assets: ComparisonAsset.allCases
    )
}
