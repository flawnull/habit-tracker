//
//  AppDelegate.swift
//  habit-tracker
//

import SwiftUI
import SwiftData
import FirebaseCore

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if AppConfig.isFirebaseConfigured {
            FirebaseApp.configure()
        } else {
            print("[HabitTracker] GoogleService-Info.plist not found. Running in local demo mode.")
        }
        return true
    }
}

@main
struct HabitTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthenticationManager()
    @State private var isLoading = true
    @AppStorage("appearance") private var appearance: AppearanceMode = .system

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Habit.self, HabitCompletion.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                AppBackground()

                if isLoading {
                    LaunchScreenView()
                        .transition(.opacity.combined(with: .scale(scale: 1.05)))
                } else if authManager.isAuthenticated {
                    ContentView()
                        .transition(.opacity)
                } else {
                    LoginView()
                        .transition(.opacity)
                }
            }
            .environmentObject(authManager)
            .animation(.easeInOut(duration: 0.45), value: isLoading)
            .animation(.easeInOut(duration: 0.45), value: authManager.isAuthenticated)
            .preferredColorScheme(appearance.colorScheme)
            .task {
                try? await Task.sleep(for: .seconds(1.2))
                isLoading = false
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
