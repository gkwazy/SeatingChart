//
//  AppStateManager.swift
//  SeatingChart
//
//  Created by GKWazy Software
//

import Foundation
import SwiftUI

class AppStateManager: ObservableObject {
    static let shared = AppStateManager()

    @Published var storageMode: StorageMode {
        didSet {
            UserDefaults.standard.set(storageMode.rawValue, forKey: "storageMode")
        }
    }

    @Published var privacyModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(privacyModeEnabled, forKey: "privacyModeEnabled")
        }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }

    init() {
        // Load from UserDefaults
        if let storageModeString = UserDefaults.standard.string(forKey: "storageMode"),
           let mode = StorageMode(rawValue: storageModeString) {
            self.storageMode = mode
        } else {
            self.storageMode = .local // Default
        }

        self.privacyModeEnabled = UserDefaults.standard.bool(forKey: "privacyModeEnabled")
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    func completeOnboarding(with mode: StorageMode) {
        self.storageMode = mode
        self.hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
    }

    // Computed property for CloudKit usage
    var isUsingCloudKit: Bool {
        get {
            storageMode == .iCloud
        }
    }

    // Set storage mode from boolean
    func setStorageMode(_ usingCloudKit: Bool) {
        storageMode = usingCloudKit ? .iCloud : .local
    }
}
