//
//  AuthService.swift
//  Birirkimtakip
//
//  Firebase Authentication (email/şifre) sarmalayıcısı.
//

import Foundation
import Combine
import FirebaseAuth

enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case userNotFound
    case wrongPassword
    case operationNotAllowed
    case networkError
    case tooManyRequests
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:         return "Geçersiz e-posta adresi."
        case .weakPassword:         return "Şifre en az 6 karakter olmalı."
        case .emailAlreadyInUse:    return "Bu e-posta ile kayıtlı bir kullanıcı var."
        case .userNotFound:         return "Kullanıcı bulunamadı."
        case .wrongPassword:        return "Şifre yanlış."
        case .operationNotAllowed:  return "E-posta/şifre girişi Firebase Console'da etkin değil."
        case .networkError:         return "İnternet bağlantısı yok ya da yavaş."
        case .tooManyRequests:      return "Çok fazla deneme. Biraz bekleyip tekrar deneyin."
        case .unknown(let msg):     return msg
        }
    }

    /// Firebase'in NSError kodlarını yerel enum'a çevirir.
    /// Konsola detay basar — Xcode Debug Area'da hatayı görebilirsin.
    static func from(_ error: Error) -> AuthError {
        let ns = error as NSError
        print("🔥 Firebase Auth error → domain=\(ns.domain) code=\(ns.code) msg=\(ns.localizedDescription)")
        print("🔥 userInfo=\(ns.userInfo)")

        guard ns.domain == AuthErrorDomain else {
            return .unknown(error.localizedDescription)
        }
        switch AuthErrorCode(rawValue: ns.code) {
        case .invalidEmail:                  return .invalidEmail
        case .weakPassword:                  return .weakPassword
        case .emailAlreadyInUse:             return .emailAlreadyInUse
        case .userNotFound:                  return .userNotFound
        case .wrongPassword, .invalidCredential:
                                             return .wrongPassword
        case .operationNotAllowed:           return .operationNotAllowed
        case .networkError:                  return .networkError
        case .tooManyRequests:               return .tooManyRequests
        default:                             return .unknown("Kod \(ns.code): \(ns.localizedDescription)")
        }
    }
}

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var currentUserId: String?
    @Published private(set) var currentEmail: String?
    @Published private(set) var isAuthenticated: Bool = false

    private var authStateListener: AuthStateDidChangeListenerHandle?

    private init() {
        // Firebase'in mevcut oturumu değişimini dinle.
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.apply(user: user)
            }
        }
        // İlk durumu hemen uygula (listener bazen ilk çağrıyı erteler).
        apply(user: Auth.auth().currentUser)
    }

    deinit {
        if let handle = authStateListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Public API

    func signIn(email: String, password: String) async throws {
        let email = normalize(email)
        try validateLocal(email: email, password: password)
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            apply(user: result.user)
        } catch {
            throw AuthError.from(error)
        }
    }

    func register(email: String, password: String) async throws {
        let email = normalize(email)
        try validateLocal(email: email, password: password)
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            apply(user: result.user)
        } catch {
            throw AuthError.from(error)
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            // Sessiz geç — zaten oturumu düşüreceğiz.
        }
        apply(user: nil)
    }

    // MARK: - Helpers

    private func apply(user: FirebaseAuth.User?) {
        currentUserId = user?.uid
        currentEmail = user?.email
        isAuthenticated = user != nil
    }

    private func normalize(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Firebase kendisi de doğruluyor ama daha okunur mesaj için önden bakıyoruz.
    private func validateLocal(email: String, password: String) throws {
        guard email.contains("@"), email.contains(".") else { throw AuthError.invalidEmail }
        guard password.count >= 6 else { throw AuthError.weakPassword }
    }
}
