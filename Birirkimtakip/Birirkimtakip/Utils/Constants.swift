//
//  Constants.swift
//  Birirkimtakip
//
//  Uygulama genelinde kullanılan sabitler.
//

import Foundation

enum AppConstants {
    /// TCMB EVDS API anahtarı.
    ///
    /// Almak için:
    ///   1. https://evds2.tcmb.gov.tr adresine git, kayıt ol
    ///   2. Profil > API Anahtarı sayfasından oluştur
    ///   3. Anahtarı buraya yapıştır (tırnak içinde)
    ///
    /// UYARI: Git'e commit ediyorsan bu dosyayı .gitignore'a ekle
    ///        ya da ortam değişkeni/Info.plist üzerinden yükle.
    static let tcmbApiKey: String = "YOUR_KEY_HERE"

    /// TCMB EVDS seri kodları.
    enum EVDSSeries {
        static let usd  = "TP.DK.USD.A"   // ABD Doları Alış
        static let eur  = "TP.DK.EUR.A"   // Euro Alış
        // TCMB EVDS'te gram altın için doğrudan seri yok.
        // Kapalıçarşı külçe altın satış kullanılabilir:
        static let gold = "TP.MK.KUL.YTL" // Külçe Altın Kapalıçarşı Satış (TL/gr)
    }
}
