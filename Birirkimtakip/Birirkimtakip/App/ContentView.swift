//
//  ContentView.swift
//  Birirkimtakip
//
//  Root: giriş yapılmışsa TabView, değilse LoginView.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        Group {
            if appState.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .environmentObject(appState)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            PortfolioView()
                .tabItem {
                    Label("Portföyüm", systemImage: "briefcase.fill")
                }

            CompareView()
                .tabItem {
                    Label("Karşılaştır", systemImage: "chart.bar.xaxis")
                }
        }
    }
}

#Preview("Login") {
    ContentView()
}

#Preview("Main") {
    MainTabView()
}
