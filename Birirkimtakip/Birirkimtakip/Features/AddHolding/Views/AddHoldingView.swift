//
//  AddHoldingView.swift
//  Birirkimtakip
//

import SwiftUI

struct AddHoldingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddHoldingViewModel()

    /// Kayıt tamamlandığında caller'ı bilgilendir.
    var onSave: (Holding) -> Void = { _ in }

    var body: some View {
        NavigationStack {
            Form {
                Section("Varlık") {
                    Picker("Tür", selection: $viewModel.assetType) {
                        ForEach(AssetType.allCases) { type in
                            Label(type.displayName, systemImage: type.systemIcon)
                                .tag(type)
                        }
                    }
                }

                Section("Miktar") {
                    HStack {
                        TextField("0", value: $viewModel.amount, format: .number)
                            .keyboardType(.decimalPad)
                        Text(viewModel.assetType.unitLabel)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Not (opsiyonel)") {
                    TextField("Örn: Bankadaki mevduat", text: $viewModel.note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Yeni Varlık")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        if let holding = viewModel.buildHolding() {
                            onSave(holding)
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
            }
        }
    }
}

#Preview {
    AddHoldingView()
}
