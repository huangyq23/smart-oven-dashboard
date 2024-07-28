//
//  OvenShortcuts.swift
//  SmartOvenDashboard
//
//
import Foundation
import AppIntents

struct OvenShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartOvenIntent(),
            phrases: ["\(.applicationName) Air Fry"],
            shortTitle: "Start Air Fry",
            systemImageName: "oven"
        )
        AppShortcut(
            intent: StopOvenIntent(),
            phrases: ["\(.applicationName) Finish"],
            shortTitle: "Stop Oven",
            systemImageName: "oven"
        )
    
    }
}
