//
//  AssetComparisonChart.swift
//  Birirkimtakip
//
//  Son 1 yıl altın / USD / EUR TL getirisi (100'e normalize edilmiş).
//

import SwiftUI
import Charts
import Combine

struct AssetComparisonChart: View {
    @StateObject private var viewModel = AssetComparisonChartViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Son 1 Yıl")
                    .font(.headline)
                Spacer()
                if viewModel.isLoading {
                    ProgressView().controlSize(.small)
                }
            }

            if viewModel.points.isEmpty {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.quaternary)
                    .frame(height: 220)
                    .overlay(
                        Text(viewModel.isLoading ? "Yükleniyor…" : "Veri yok")
                            .foregroundStyle(.secondary)
                    )
            } else {
                chart
                legend
            }
        }
        .task {
            await viewModel.load()
        }
    }

    private var chart: some View {
        Chart(viewModel.points) { p in
            LineMark(
                x: .value("Tarih", p.date),
                y: .value("Getiri", p.normalized)
            )
            .foregroundStyle(by: .value("Varlık", p.asset.displayName))
            .interpolationMethod(.monotone)
        }
        .chartForegroundStyleScale([
            ComparisonAsset.gold.displayName: Color.orange,
            ComparisonAsset.usd.displayName:  Color.green,
            ComparisonAsset.eur.displayName:  Color.blue
        ])
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("\(Int(v))")
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month, count: 2)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated))
            }
        }
        .chartLegend(.hidden)
        .frame(height: 220)
    }

    private var legend: some View {
        HStack(spacing: 16) {
            ForEach([ComparisonAsset.gold, .usd, .eur]) { asset in
                HStack(spacing: 6) {
                    Circle()
                        .fill(color(for: asset))
                        .frame(width: 8, height: 8)
                    Text(asset.displayName)
                        .font(.caption)
                    if let ret = viewModel.finalReturn(for: asset) {
                        Text(String(format: "%+.1f%%", ret))
                            .font(.caption.bold())
                            .foregroundStyle(ret >= 0 ? .green : .red)
                    }
                }
            }
            Spacer()
        }
    }

    private func color(for asset: ComparisonAsset) -> Color {
        switch asset {
        case .gold: return .orange
        case .usd:  return .green
        case .eur:  return .blue
        default:    return .gray
        }
    }
}

// MARK: - ViewModel

@MainActor
final class AssetComparisonChartViewModel: ObservableObject {

    struct ChartPoint: Identifiable, Hashable {
        let asset: ComparisonAsset
        let date: Date
        let normalized: Double     // 100 baseline
        var id: String { "\(asset.rawValue)_\(date.timeIntervalSince1970)" }
    }

    @Published var points: [ChartPoint] = []
    @Published var isLoading = false

    /// Her varlığın nihai % getirisi (grafik lejandı için).
    private(set) var finalReturns: [ComparisonAsset: Double] = [:]

    func finalReturn(for asset: ComparisonAsset) -> Double? {
        finalReturns[asset]
    }

    func load() async {
        guard points.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        let from = Calendar.current.date(byAdding: .year, value: -1, to: .now) ?? .now
        var collected: [ChartPoint] = []

        for asset in [ComparisonAsset.gold, .usd, .eur] {
            do {
                let series = try await PriceHistoryService.shared.historicalSeries(
                    for: asset, from: from
                )
                guard let first = series.first?.priceTRY, first > 0 else { continue }

                let normalized = series.map {
                    ChartPoint(
                        asset: asset,
                        date: $0.date,
                        normalized: ($0.priceTRY / first) * 100
                    )
                }
                collected.append(contentsOf: normalized)

                if let last = series.last?.priceTRY {
                    finalReturns[asset] = ((last / first) - 1) * 100
                }
            } catch {
                // Sessizce atla; diğer varlıklar çizilsin.
            }
        }

        points = collected
    }
}
