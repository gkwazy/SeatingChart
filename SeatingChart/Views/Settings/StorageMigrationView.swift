//
//  StorageMigrationView.swift
//  SeatingChart
//
//  Created on 2025-11-29.
//

import SwiftUI

struct StorageMigrationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appStateManager: AppStateManager

    @State private var targetStorageMode: StorageMode
    @State private var showingMigrationConfirmation = false
    @State private var isMigrating = false
    @State private var migrationProgress: Double = 0.0
    @State private var migrationError: String?

    enum StorageMode {
        case local
        case iCloud
    }

    init() {
        _targetStorageMode = State(initialValue: .local)
    }

    var currentMode: StorageMode {
        appStateManager.isUsingCloudKit ? .iCloud : .local
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if !isMigrating {
                    // Current storage info
                    VStack(spacing: 16) {
                        Image(systemName: currentMode == .iCloud ? "icloud.fill" : "internaldrive.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Current Storage")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text(currentMode == .iCloud ? "iCloud" : "Local")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .padding()

                    Divider()
                        .padding(.horizontal)

                    // Migration options
                    VStack(spacing: 16) {
                        Text("Switch to")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        VStack(spacing: 12) {
                            StorageModeCard(
                                icon: currentMode == .local ? "icloud.fill" : "internaldrive.fill",
                                title: currentMode == .local ? "iCloud Storage" : "Local Storage",
                                description: currentMode == .local ?
                                    "Sync your data across all Apple devices" :
                                    "Store data only on this device",
                                isSelected: true
                            )
                        }
                        .padding(.horizontal)
                    }

                    Spacer()

                    // Warning message
                    VStack(spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Important")
                                    .font(.headline)

                                Text("Switching storage modes will migrate all your data. Make sure you have a backup before proceeding.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: { showingMigrationConfirmation = true }) {
                            Text("Begin Migration")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        Button(action: { dismiss() }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .padding(.bottom)
                } else {
                    // Migration in progress
                    VStack(spacing: 24) {
                        Spacer()

                        ProgressView(value: migrationProgress) {
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.left.arrow.right.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.blue)

                                Text("Migrating Data...")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                        }
                        .progressViewStyle(.linear)
                        .padding(.horizontal, 40)

                        Text("\(Int(migrationProgress * 100))%")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        if let error = migrationError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        Spacer()
                    }
                }
            }
            .navigationTitle("Storage Migration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isMigrating {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .confirmationDialog(
                "Confirm Migration",
                isPresented: $showingMigrationConfirmation,
                titleVisibility: .visible
            ) {
                Button("Migrate Data", role: .destructive) {
                    performMigration()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will move all your data to \(currentMode == .local ? "iCloud" : "local") storage. This process may take a few minutes.")
            }
        }
        .interactiveDismissDisabled(isMigrating)
    }

    private func performMigration() {
        isMigrating = true
        migrationError = nil

        // Simulate migration progress
        Task {
            for i in 0...10 {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await MainActor.run {
                    migrationProgress = Double(i) / 10.0
                }
            }

            await MainActor.run {
                // Switch storage mode
                let newMode = currentMode == .local
                appStateManager.setStorageMode(newMode)

                // Complete migration
                isMigrating = false
                dismiss()
            }
        }
    }
}

struct StorageModeCard: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(.blue)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    StorageMigrationView()
        .environmentObject(AppStateManager())
}
