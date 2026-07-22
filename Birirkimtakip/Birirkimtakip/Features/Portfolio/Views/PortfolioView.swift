//
//  PortfolioView.swift
//  Birirkimtakip
//
//  Yalın portföy: varlıklar + toplam.
//

import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = PortfolioViewModel()
    @State private var showingAddHolding = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    PortfolioSummaryView(totalValueTRY: viewModel.totalValueTRY)
                }

                Section("Varlıklarım") {
                    if viewModel.holdings.isEmpty {
                        ContentUnavailableView(
                            "Henüz varlık yok",
                            systemImage: "tray",
                            description: Text("Sağ üstteki + ile ekle.")
                        )
                    } else {
                        ForEach(viewModel.holdings) { holding in
                            HoldingRowView(
                                holding: holding,
                                valueTRY: viewModel.valueTRY(for: holding)
                            )
                        }
                        .onDelete(perform: viewModel.delete)
                    }
                }
            }
            .navigationTitle("Portföyüm")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        if let email = appState.currentEmail {
                            Text(email)
                        }
                        Button(role: .destructive) {
                            appState.signOut()
                        } label: {
                            Label("Çıkış Yap", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddHolding = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHolding) {
                AddHoldingView { newHolding in
                    Task { await viewModel.add(newHolding) }
                }
            }
            .refreshable {
                await viewModel.load()
            }
            .task {
                await viewModel.load()
            }
        }
    }
}

#Preview {
    PortfolioView()
}
