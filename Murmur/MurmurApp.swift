import SwiftUI

@main
struct MurmurApp: App {
    @StateObject private var menuBarManager = MenuBarManager()
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(settingsManager)
        }
    }
    
    init() {
        // Hide dock icon for menu bar only app
        // NSApp might be nil during init, so we'll set this in MenuBarManager instead
    }
}