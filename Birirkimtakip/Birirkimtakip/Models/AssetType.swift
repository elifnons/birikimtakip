//
//  AssetType.swift
//  Birirkimtakip
//
//  Portföyde tutulabilen basit varlık türleri.
//  Sadeleştirilmiş kapsam: TL, altın, USD, EUR.
//

import Foundation

enum AssetType: String, Codable, CaseIterable, Identifiable {
    case tryCash = "TRY"
    case gold    = "GRAM"
    case usd     = "USD"
    case eur     = "EUR"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tryCash: return "Türk Lirası"
        case .gold:    return "Gram Altın"
        case .usd:     return "Dolar"
        case .eur:     return "Euro"
        }
    }

    var unitLabel: String {
        switch self {
        case .tryCash: return "TL"
        case .gold:    return "gram"
        case .usd:     return "USD"
        case .eur:     return "EUR"
        }
    }

    var systemIcon: String {
        switch self {
        case .tryCash: return "turkishlirasign.circle.fill"
        case .gold:    return "circle.hexagongrid.fill"
        case .usd:     return "dollarsign.circle.fill"
        case .eur:     return "eurosign.circle.fill"
        }
    }

    /// Fiyat karşılaştırması için ComparisonAsset karşılığı (TL nakit için nil).
    var comparisonAsset: ComparisonAsset? {
        switch self {
        case .tryCash: return nil
        case .gold:    return .gold
        case .usd:     return .usd
        case .eur:     return .eur
        }
    }
}
