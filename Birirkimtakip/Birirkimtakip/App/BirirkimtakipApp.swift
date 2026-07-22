//
//  BirirkimtakipApp.swift
//  Birirkimtakip
//
//  Created by ANB on 21.07.2026.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

// MARK: - AppDelegate (Firebase kurulum için)

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        BirirkimtakipApp.logFirebaseState()
        return true
    }
}

// MARK: - App

@main
struct BirirkimtakipApp: App {
    // Firebase kurulumu için AppDelegate'i SwiftUI'a bağla.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    /// Uygulama açılınca Firebase config'ini konsola bas — tanılama için.
    static func logFirebaseState() {
        if let app = FirebaseApp.app() {
            let opts = app.options
            print("🟢 Firebase configured")
            print("   projectID   = \(opts.projectID ?? "nil")")
            print("   googleAppID = \(opts.googleAppID)")
            print("   bundleID    = \(opts.bundleID)")
            print("   apiKey      = \(opts.apiKey?.prefix(12) ?? "nil")…")
        } else {
            print("🔴 Firebase NOT configured — GoogleService-Info.plist eksik ya da bundle'a dahil değil.")
        }
        if let bundleID = Bundle.main.bundleIdentifier {
            print("   appBundleID = \(bundleID)")
        }
    }
}
