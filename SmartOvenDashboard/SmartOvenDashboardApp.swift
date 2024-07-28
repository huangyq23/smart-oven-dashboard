//
//  SmartOvenDashboardApp.swift
//  SmartOvenDashboard
//
//

import SwiftUI
import GRDBQuery

@main
struct SmartOvenDashboardApp: App {
    
    var displaySettingsManager = DisplaySettingsManager()
    
    init() {
        OvenShortcuts.updateAppShortcutParameters()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView().environment(\.appDatabase, .shared)
        }
        .environmentObject(displaySettingsManager)
    }
}


// MARK: - Give SwiftUI access to the database
//
// Define a new environment key that grants access to an AppDatabase.
//
// The technique is documented at
// <https://developer.apple.com/documentation/swiftui/environmentkey>.

private struct AppDatabaseKey: EnvironmentKey {
    static var defaultValue: AppDatabase { .empty() }
}

extension EnvironmentValues {
    var appDatabase: AppDatabase {
        get { self[AppDatabaseKey.self] }
        set { self[AppDatabaseKey.self] = newValue }
    }
}

extension Query where Request.DatabaseContext == AppDatabase {
    /// Convenience initializer for requests that feed from `AppDatabase`.
    init(_ request: Request) {
        self.init(request, in: \.appDatabase)
    }
}


extension UIApplication {
    var firstKeyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .first?.keyWindow
    }
}
