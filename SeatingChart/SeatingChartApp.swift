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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appStateManager)
        }
    }
}
