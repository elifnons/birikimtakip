//
//  Holding.swift
//  Birirkimtakip
//
//  Portföydeki tek varlık. Sadeleştirildi: sadece tür + miktar.
//  Alış fiyatı / tarih / komisyon takip edilmez (kâr/zarar hesaplanmaz).
//

import Foundation

struct Holding: Identifiable, Codable, Hashable {
    var id: String
    var assetType: AssetType
    var amount: Double     // TL için TL tutar, altın için gram, döviz için birim
    var note: String?

    /// Verilen anlık birim TL fiyatına göre TL karşılığı.
    /// TL nakit için amount = TL değeri, o yüzden fiyat 1 kabul edilir.
    func valueTRY(unitPriceTRY: Double) -> Double {
        assetType == .tryCash ? amount : amount * unitPriceTRY
    }
}
