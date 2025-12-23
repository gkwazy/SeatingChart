//
//  SettingsView.swift
//  SeatingChart
//
//  Created on 2025-11-29.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appStateManager: AppStateManager
    @State private var showingStorageMigration = false
    @State private var showingAbout = false
    @State private var showingTestDataAlert = false

    var body: some View {
        List {
            // Storage Section
            Section(header: Text("Storage")) {
                HStack {
                    Label("Storage Mode", systemImage: appStateManager.isUsingCloudKit ? "icloud.fill" : "internaldrive.fill")

                    Spacer()

                    Text(appStateManager.isUsingCloudKit ? "iCloud" : "Local")
                        .foregroundColor(.secondary)
                }

                Button(action: { showingStorageMigration = true }) {
                    Label("Change Storage Mode", systemImage: "arrow.left.arrow.right")
                }
            }

            // Data Management Section - Phase 2
            // Export/Import features coming in future update

            // Demo Data Section
            Section(header: Text("Demo Data"), footer: Text("Generate sample data for testing and demonstration purposes.")) {
                Button(action: { showingTestDataAlert = true }) {
                    Label("Generate Test Math Class", systemImage: "flask.fill")
                        .foregroundColor(.blue)
                }

                Button(action: deleteMathClass) {
                    Label("Delete Test Math Class", systemImage: "trash.fill")
                        .foregroundColor(.red)
                }
            }

            // Preferences Section
            Section(header: Text("Preferences")) {
                NavigationLink(destination: NotificationSettingsView()) {
                    Label("Notifications", systemImage: "bell.fill")
                }

                NavigationLink(destination: AppearanceSettingsView()) {
                    Label("Appearance", systemImage: "paintbrush.fill")
                }
            }

            // About Section
            Section(header: Text("About")) {
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                Button(action: { showingAbout = true }) {
                    Label("About Seating Chart", systemImage: "app.fill")
                }

            }

        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingStorageMigration) {
            StorageMigrationView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .alert("Generate Test Data", isPresented: $showingTestDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Generate") {
                generateTestMathClass()
            }
        } message: {
            Text("This will create a Math class with 20 students, each with a colorful profile picture.")
        }
    }

    // MARK: - Test Data Functions

    private func generateTestMathClass() {
        TestDataGenerator.generateMathClassWithStudents(context: viewContext)
    }

    private func deleteMathClass() {
        TestDataGenerator.deleteMathClass(context: viewContext)
    }
}

struct NotificationSettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled = false
    @AppStorage("reminderTimeInterval") private var reminderTimeInterval: Double = Date().timeIntervalSince1970

    private var reminderTime: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: reminderTimeInterval) },
            set: { reminderTimeInterval = $0.timeIntervalSince1970 }
        )
    }

    var body: some View {
        Form {
            Section {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
            }

            Section(header: Text("Daily Reminders")) {
                Toggle("Daily Attendance Reminder", isOn: $dailyReminderEnabled)
                    .disabled(!notificationsEnabled)

                if dailyReminderEnabled {
                    DatePicker("Reminder Time", selection: reminderTime, displayedComponents: .hourAndMinute)
                }
            }
        }
        .navigationTitle("Notifications")
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("colorScheme") private var colorScheme = "system"

    var body: some View {
        Form {
            Section(header: Text("Theme")) {
                Picker("Appearance", selection: $colorScheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.inline)
            }
        }
        .navigationTitle("Appearance")
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "studentdesk")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("Seating Chart")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("A classroom management app for organizing seating arrangements and tracking attendance.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                Text("Made with care for educators")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppStateManager())
    }
}
