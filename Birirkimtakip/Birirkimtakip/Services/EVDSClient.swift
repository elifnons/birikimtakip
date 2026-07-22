//
//  EVDSClient.swift
//  Birirkimtakip
//
//  TCMB EVDS (Elektronik Veri Dağıtım Sistemi) API istemcisi.
//  Dokümantasyon: https://evds2.tcmb.gov.tr/help/videos/EVDS_Web_Service_Usage_Guide.pdf
//

import Foundation

enum EVDSError: LocalizedError {
    case missingApiKey
    case badURL
    case httpError(Int)
    case noData(String)
    case parseError

    var errorDescription: String? {
        switch self {
        case .missingApiKey:      return "TCMB API anahtarı eksik. Constants.swift'e ekleyin."
        case .badURL:             return "Geçersiz URL"
        case .httpError(let c):   return "HTTP hatası: \(c)"
        case .noData(let s):      return "Seri için veri yok: \(s)"
        case .parseError:         return "Yanıt çözümlenemedi"
        }
    }
}

@MainActor
final class EVDSClient {
    static let shared = EVDSClient()

    private let baseURL = "https://evds2.tcmb.gov.tr/service/evds/"

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd-MM-yyyy"       // EVDS gg-aa-yyyy istiyor
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Europe/Istanbul")
        return f
    }()

    private init() {}

    // MARK: - Public

    /// Bir serinin verilen tarihe en yakın (o gün ya da öncesi) değerini döndürür.
    /// Hafta sonu / tatil için 7 gün geriye kadar tarar.
    func value(series: String, on date: Date) async throws -> Double {
        let apiKey = AppConstants.tcmbApiKey
        guard !apiKey.isEmpty, apiKey != "YOUR_KEY_HERE" else {
            throw EVDSError.missingApiKey
        }

        // 7 günlük pencere: TCMB'nin veri yayımlamadığı günler için tampon.
        let start = Calendar.current.date(byAdding: .day, value: -7, to: date) ?? date
        let startStr = dateFormatter.string(from: start)
        let endStr   = dateFormatter.string(from: date)

        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "series",    value: series),
            URLQueryItem(name: "startDate", value: startStr),
            URLQueryItem(name: "endDate",   value: endStr),
            URLQueryItem(name: "type",      value: "json"),
            URLQueryItem(name: "key",       value: apiKey)
        ]
        guard let url = components?.url else { throw EVDSError.badURL }

        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw EVDSError.httpError(http.statusCode)
        }

        return try parseLastValue(data: data, series: series)
    }

    // MARK: - Parsing

    /// EVDS yanıt formatı:
    /// {
    ///   "totalCount": 5,
    ///   "items": [
    ///     { "Tarih": "14-07-2026", "TP_DK_USD_A": "40.1234", "UNIXTIME": ... },
    ///     ...
    ///   ]
    /// }
    private func parseLastValue(data: Data, series: String) throws -> Double {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["items"] as? [[String: Any]] else {
            throw EVDSError.parseError
        }

        // Seri adında . yerine _ kullanılır.
        let key = series.replacingOccurrences(of: ".", with: "_")

        // En yeni tarihten geriye doğru geçerli değeri ara.
        for item in items.reversed() {
            if let stringValue = item[key] as? String,
               let value = Double(stringValue.replacingOccurrences(of: ",", with: ".")) {
                return value
            }
            if let doubleValue = item[key] as? Double {
                return doubleValue
            }
        }
        throw EVDSError.noData(series)
    }
}
