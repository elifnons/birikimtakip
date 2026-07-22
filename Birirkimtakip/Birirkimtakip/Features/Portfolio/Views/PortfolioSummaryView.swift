//
//  PortfolioSummaryView.swift
//  Birirkimtakip
//

import SwiftUI

struct PortfolioSummaryView: View {
    let totalValueTRY: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Toplam Varlık")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(totalValueTRY.formatAsTRY())
                .font(.largeTitle.bold())
                .contentTransition(.numericText())
        }
        .padding(.vertical, 6)
    }
}
