//
//  ComparisonAsset.swift
//  Birirkimtakip
//
//  Karşılaştırılacak seçenekler: banka faizleri + altın + döviz.
//

import Foundation

enum ComparisonAsset: String, Codable, CaseIterable, Identifiable {
    case bankDaily   = "BANK_DAILY"     // Günlük faiz (vadesiz+günlük)
    case bankMonthly = "BANK_MONTHLY"   // Aylık vadeli mevduat
    case gold        = "GRAM"
    case usd         = "USD"
    case eur         = "EUR"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bankDaily:   return "Günlük Faiz"
        case .bankMonthly: return "Vadeli Mevduat"
        case .gold:        return "Gram Altın"
        case .usd:         return "Dolar"
        case .eur:         return "Euro"
        }
    }

    var unitLabel: String {
        switch self {
        case .bankDaily, .bankMonthly: return "TL"
        case .gold:                    return "gram"
        case .usd:                     return "USD"
        case .eur:                     return "EUR"
        }
    }

    var systemIcon: String {
        switch self {
        case .bankDaily:   return "clock.arrow.circlepath"
        case .bankMonthly: return "banknote.fill"
        case .gold:        return "circle.hexagongrid.fill"
        case .usd:         return "dollarsign.circle.fill"
        case .eur:         return "eurosign.circle.fill"
        }
    }

    /// Banka mı fiziksel varlık mı?
    var isBankProduct: Bool {
        self == .bankDaily || self == .bankMonthly
    }
}
