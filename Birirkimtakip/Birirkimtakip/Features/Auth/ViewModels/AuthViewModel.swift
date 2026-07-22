//
//  AuthViewModel.swift
//  Birirkimtakip
//

import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var passwordConfirm: String = ""

    @Published var isLoading = false
    @Published var errorMessage: String?

    var canSubmitLogin: Bool {
        !email.isEmpty && password.count >= 6 && !isLoading
    }

    var canSubmitRegister: Bool {
        canSubmitLogin && password == passwordConfirm
    }

    func signIn() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await AuthService.shared.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func register() async {
        errorMessage = nil
        guard password == passwordConfirm else {
            errorMessage = "Şifreler eşleşmiyor."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await AuthService.shared.register(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
