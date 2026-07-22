//
//  CompareView.swift
//  Birirkimtakip
//
//  "X TL'yi Y süre önce altına mı dövize mi koysaydım?" ekranı.
//

import SwiftUI

struct CompareView: View {
    @StateObject private var viewModel = CompareViewModel()
    @FocusState private var amountFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                inputSection
                resultsSection
                chartSection
                disclaimerSection
            }
            .navigationTitle("Karşılaştır")
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Spacer()
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Tamam") { amountFocused = false }
                }
            }
            .task {
                await viewModel.run()
            }
        }
    }

    // MARK: - Sections

    private var inputSection: some View {
        Section("Ne kadar, ne zaman?") {
            HStack {
                Text("Tutar")
                Spacer()
                TextField(
                    "10.000",
                    value: $viewModel.scenario.amountTRY,
                    format: .number
                )
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .focused($amountFocused)
                Text("₺")
                    .foregroundStyle(.secondary)
            }

            Picker("Süre", selection: $viewModel.scenario.period) {
                ForEach(ComparePeriod.allCases) { period in
                    Text(period.displayName).tag(period)
                }
            }
            .pickerStyle(.segmented)

            Button {
                Task { await viewModel.run() }
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Label("Hesapla", systemImage: "arrow.right.circle.fill")
                    }
                    Spacer()
                }
            }
            .buttonStyle(.borderedProminent)
            .listRowInsets(EdgeInsets())
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var resultsSection: some View {
        if !viewModel.results.isEmpty {
            Section("Sonuç") {
                if let winner = viewModel.winner {
                    WinnerBanner(result: winner, period: viewModel.scenario.period)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                ForEach(viewModel.rankedResults) { result in
                    CompareResultRow(result: result)
                }
            }
        }
    }

    private var chartSection: some View {
        Section {
            AssetComparisonChart()
                .padding(.vertical, 8)
        } header: {
            Text("Geçmiş Getiri")
        }
    }

    private var disclaimerSection: some View {
        Section {
            Text("Bu hesaplama geçmiş fiyatlara dayanır. Geleceğe dair garanti değildir.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Alt bileşenler

private struct WinnerBanner: View {
    let result: CompareResult
    let period: ComparePeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                Text("Kazanan")
                    .font(.caption.bold())
                    .textCase(.uppercase)
            }
            .foregroundStyle(.white.opacity(0.9))

            Text(result.asset.displayName)
                .font(.title.bold())
                .foregroundStyle(.white)

            HStack(spacing: 4) {
                Image(systemName: "arrow.up.right")
                Text(String(format: "%+.2f%%", result.profitPercent))
                    .bold()
                Text("son \(period.displayName.lowercased())")
                    .opacity(0.85)
            }
            .foregroundStyle(.white)
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                colors: [.orange, .yellow],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.vertical, 4)
    }
}

private struct CompareResultRow: View {
    let result: CompareResult

    private var subtitle: String {
        if result.asset.isBankProduct {
            return "\(result.profitTRY.formatAsTRY()) net faiz"
        } else {
            return String(
                format: "%.4f %@ alınabilirdi",
                result.unitsBought,
                result.asset.unitLabel
            )
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: result.asset.systemIcon)
                .font(.title2)
                .frame(width: 32)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.asset.displayName)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(result.currentValueTRY.formatAsTRY())
                    .font(.subheadline.bold())
                Text(String(format: "%+.2f%%", result.profitPercent))
                    .font(.caption.bold())
                    .foregroundStyle(result.profitPercent >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CompareView()
}
