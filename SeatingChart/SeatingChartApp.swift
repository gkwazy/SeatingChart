//
//  SeatingChartApp.swift
//  SeatingChart
//
//  Created by Garret Wasden on 11/29/25.
//

import SwiftUI

@main
struct SeatingChartApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var appStateManager = AppStateManager()
    @AppStorage("colorScheme") private var colorScheme = "system"

    private var preferredColorScheme: ColorScheme? {
        switch colorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil  // "system" follows device setting
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appStateManager)
                .preferredColorScheme(preferredColorScheme)
        }
    }
}
