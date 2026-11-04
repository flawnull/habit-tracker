//
//  AuthenticationManager.swift
//  habit-tracker
//
//  Created by Ivan Kharitonenko on 31/10/2025.
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import Combine

enum AppConfig {
    /// Firebase is optional. Without `GoogleService-Info.plist` the app runs in local demo mode.
    static let isFirebaseConfigured: Bool =
        Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil

    /// True once `FirebaseApp.configure()` has run (false in previews and demo mode).
    static var isFirebaseReady: Bool { FirebaseApp.app() != nil }

    static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    static let repositoryURL = URL(string: "https://github.com/flawnull/habit-tracker")!
}

@MainActor
final class AuthenticationManager: ObservableObject {
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isGuest = false
    @Published private(set) var displayName = ""
    @Published private(set) var email = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private static let guestKey = "auth.guestMode"
    private var authStateHandler: AuthStateDidChangeListenerHandle?

    var firstName: String {
        displayName.split(separator: " ").first.map(String.init) ?? ""
    }

    init() {
        if UserDefaults.standard.bool(forKey: Self.guestKey) {
            enterGuestMode()
        }
        if AppConfig.isFirebaseReady {
            registerAuthStateHandler()
        }
    }

    private func registerAuthStateHandler() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                guard let self, !self.isGuest else { return }
                self.apply(user)
            }
        }
    }

    private func apply(_ user: User?) {
        isAuthenticated = user != nil
        displayName = user?.displayName ?? ""
        email = user?.email ?? ""
    }

    // MARK: Guest mode

    func enterGuestMode() {
        UserDefaults.standard.set(true, forKey: Self.guestKey)
        isGuest = true
        displayName = "Guest"
        email = "Local profile, stored on this device"
        isAuthenticated = true
    }

    // MARK: Firebase

    private func requireFirebase() throws {
        guard AppConfig.isFirebaseReady else {
            errorMessage = AuthError.firebaseMissing.errorDescription
            throw AuthError.firebaseMissing
        }
    }

    func signIn(email: String, password: String) async throws {
        try requireFirebase()
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            apply(result.user)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func signUp(email: String, password: String, fullName: String) async throws {
        try requireFirebase()
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)

            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = fullName
            try await changeRequest.commitChanges()

            let userData: [String: Any] = [
                "uid": result.user.uid,
                "email": email,
                "fullName": fullName,
                "createdAt": Timestamp(date: Date())
            ]
            try await Firestore.firestore()
                .collection("users")
                .document(result.user.uid)
                .setData(userData)

            apply(result.user)
            displayName = fullName
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func refreshProfile() {
        guard AppConfig.isFirebaseReady, !isGuest, let user = Auth.auth().currentUser else { return }
        user.reload { [weak self] _ in
            Task { @MainActor in
                self?.apply(Auth.auth().currentUser)
            }
        }
    }

    func signOut() throws {
        if isGuest {
            UserDefaults.standard.set(false, forKey: Self.guestKey)
            isGuest = false
            apply(nil)
            return
        }
        guard AppConfig.isFirebaseReady else { return }
        try Auth.auth().signOut()
        apply(nil)
    }

    func resetPassword(email: String) async throws {
        try requireFirebase()
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
}

enum AuthError: LocalizedError {
    case firebaseMissing

    var errorDescription: String? {
        switch self {
        case .firebaseMissing:
            return "Accounts need Firebase. Add GoogleService-Info.plist (see FIREBASE_SETUP.md) or continue in demo mode."
        }
    }
}
