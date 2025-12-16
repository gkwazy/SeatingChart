//
//  StorageSelectionView.swift
//  SeatingChart
//
//  Created on 2025-11-29.
//

import SwiftUI

struct StorageSelectionView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @State private var selectedStorage: StorageMode = .local

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Header
                VStack(spacing: 12) {
                    Image(systemName: "tray.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Choose Storage")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Select where to store your classroom data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Storage options
                VStack(spacing: 16) {
                    StorageOptionCard(
                        icon: "icloud.fill",
                        title: "iCloud Storage",
                        description: "Sync across all your Apple devices",
                        isSelected: selectedStorage == .iCloud
                    ) {
                        selectedStorage = .iCloud
                    }

                    StorageOptionCard(
                        icon: "internaldrive.fill",
                        title: "Local Storage",
                        description: "Store data only on this device",
                        isSelected: selectedStorage == .local
                    ) {
                        selectedStorage = .local
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Continue button
                Button(action: {
                    appStateManager.completeOnboarding(with: selectedStorage)
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct StorageOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.1), radius: isSelected ? 8 : 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    StorageSelectionView()
        .environmentObject(AppStateManager())
}
