//
//  YahooFinanceClient.swift
//  Birirkimtakip
//
//  API anahtarı gerektirmeyen Yahoo Finance chart endpoint istemcisi.
//  Not: Yahoo Finance resmi bir API değildir; endpoint uzun süredir stabil
//  ama teorik olarak değişebilir. Üretim için TCMB EVDS'e geçmek daha güvenli.
//

import Foundation

enum YahooError: LocalizedError {
    case badURL
    case httpError(Int)
    case emptyResponse
    case parseError

    var errorDescription: String? {
        switch self {
        case .badURL:           return "Geçersiz URL"
        case .httpError(let c): return "HTTP hatası: \(c)"
        case .emptyResponse:    return "Boş yanıt"
        case .parseError:       return "Yanıt çözümlenemedi"
        }
    }
}

@MainActor
final class YahooFinanceClient {
    static let shared = YahooFinanceClient()

    private let base = "https://query1.finance.yahoo.com/v8/finance/chart/"

    private init() {}

    // MARK: - Public

    /// (Tarih, kapanış) çiftlerinden oluşan zaman serisi.
    struct DailyClose: Hashable {
        let date: Date
        let close: Double
    }

    /// Verilen sembol için günlük kapanış serisi.
    /// - Parameters:
    ///   - symbol: "USDTRY=X", "EURTRY=X", "XAUUSD=X"
    ///   - from: başlangıç tarihi (dahil)
    ///   - to: bitiş tarihi (dahil)
    func historicalCloses(
        symbol: String,
        from: Date,
        to: Date = .now
    ) async throws -> [DailyClose] {
        var comp = URLComponents(string: base + symbol)
        comp?.queryItems = [
            URLQueryItem(name: "period1",  value: String(Int(from.timeIntervalSince1970))),
            URLQueryItem(name: "period2",  value: String(Int(to.timeIntervalSince1970))),
            URLQueryItem(name: "interval", value: "1d")
        ]
        guard let url = comp?.url else { throw YahooError.badURL }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw YahooError.httpError(http.statusCode)
        }

        return try parseSeries(data: data)
    }

    /// Bir sembolün verilen tarihe en yakın (o gün veya öncesi) kapanış fiyatı.
    /// - Parameter symbol: "USDTRY=X", "EURTRY=X", "XAUUSD=X" gibi
    func closePrice(symbol: String, on date: Date) async throws -> Double {
        // Hedef tarihin ±7 günlük bir penceresini iste (hafta sonu/tatil için tampon).
        let start = Calendar.current.date(byAdding: .day, value: -10, to: date) ?? date
        let end   = Calendar.current.date(byAdding: .day, value: 1,   to: date) ?? date

        var comp = URLComponents(string: base + symbol)
        comp?.queryItems = [
            URLQueryItem(name: "period1",  value: String(Int(start.timeIntervalSince1970))),
            URLQueryItem(name: "period2",  value: String(Int(end.timeIntervalSince1970))),
            URLQueryItem(name: "interval", value: "1d")
        ]
        guard let url = comp?.url else { throw YahooError.badURL }

        var request = URLRequest(url: url)
        // Yahoo user-agent isteyebilir; boş bırakınca bazen 403 döner.
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw YahooError.httpError(http.statusCode)
        }

        return try parseLastClose(data: data, targetDate: date)
    }

    // MARK: - Parsing

    /// Yahoo response'unda gezip hedef tarihe eşit veya önceki en son
    /// non-nil kapanış değerini döndürür.
    private func parseLastClose(data: Data, targetDate: Date) throws -> Double {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let chart = json["chart"] as? [String: Any],
              let results = chart["result"] as? [[String: Any]],
              let first = results.first,
              let timestamps = first["timestamp"] as? [Int],
              let indicators = first["indicators"] as? [String: Any],
              let quotes = indicators["quote"] as? [[String: Any]],
              let quote = quotes.first,
              let closes = quote["close"] as? [Any] else {
            throw YahooError.parseError
        }

        guard !timestamps.isEmpty else { throw YahooError.emptyResponse }

        let targetTs = Int(targetDate.timeIntervalSince1970)

        // Sondan başa doğru, hedef tarihe eşit/önce ilk non-nil close bul.
        for i in stride(from: timestamps.count - 1, through: 0, by: -1) {
            let ts = timestamps[i]
            if ts > targetTs { continue }
            if let value = closes[i] as? Double, !value.isNaN {
                return value
            }
        }

        // Hedef günden geriye veri yoksa penceredeki son geçerli kapanışı al.
        for value in closes.reversed() {
            if let d = value as? Double, !d.isNaN { return d }
        }

        throw YahooError.emptyResponse
    }

    /// Yahoo yanıtından tüm (timestamp, close) çiftlerini seri olarak parse eder.
    private func parseSeries(data: Data) throws -> [DailyClose] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let chart = json["chart"] as? [String: Any],
              let results = chart["result"] as? [[String: Any]],
              let first = results.first,
              let timestamps = first["timestamp"] as? [Int],
              let indicators = first["indicators"] as? [String: Any],
              let quotes = indicators["quote"] as? [[String: Any]],
              let quote = quotes.first,
              let closes = quote["close"] as? [Any] else {
            throw YahooError.parseError
        }

        var out: [DailyClose] = []
        for (i, ts) in timestamps.enumerated() where i < closes.count {
            if let v = closes[i] as? Double, !v.isNaN {
                out.append(DailyClose(date: Date(timeIntervalSince1970: TimeInterval(ts)), close: v))
            }
        }
        return out
    }
}
