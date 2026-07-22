//
//  AppState.swift
//  Birirkimtakip
//
//  Uygulamanın global durumu. AuthService'i dinler, giriş/çıkışta
//  ContentView'ın otomatik olarak doğru ekrana atmasını sağlar.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUserId: String? = nil
    @Published var currentEmail: String? = nil
    @Published var displayCurrency: String = "TRY"

    private var cancellables = Set<AnyCancellable>()

    init() {
        let auth = AuthService.shared

        // Başlangıç durumunu senkronize et
        self.isLoggedIn    = auth.isAuthenticated
        self.currentUserId = auth.currentUserId
        self.currentEmail  = auth.currentEmail

        // AuthService'teki değişiklikleri dinle
        auth.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.isLoggedIn = value
            }
            .store(in: &cancellables)

        auth.$currentUserId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.currentUserId = value
            }
            .store(in: &cancellables)

        auth.$currentEmail
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.currentEmail = value
            }
            .store(in: &cancellables)
    }

    func signOut() {
        AuthService.shared.signOut()
    }
}
