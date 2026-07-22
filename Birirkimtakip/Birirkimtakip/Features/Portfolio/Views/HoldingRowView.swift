//
//  HoldingRowView.swift
//  Birirkimtakip
//

import SwiftUI

struct HoldingRowView: View {
    let holding: Holding
    let valueTRY: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: holding.assetType.systemIcon)
                .font(.title2)
                .frame(width: 32)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(holding.assetType.displayName)
                    .font(.headline)
                Text("\(holding.amount.formatted()) \(holding.assetType.unitLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(valueTRY.formatAsTRY())
                .font(.subheadline.bold())
        }
        .padding(.vertical, 4)
    }
}
