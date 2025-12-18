//
//  ClassTabView.swift
//  SeatingChart
//
//  Tab-based navigation for a selected class
//  Provides quick access to Seating Chart, Attendance History, Roster, and Settings
//  Redesigned with Schoolhouse Modern aesthetic
//

import SwiftUI
import CoreData

struct ClassTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var classPeriod: ClassPeriod
    @EnvironmentObject var appStateManager: AppStateManager

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Seating Chart (Default)
            MainSeatingChartView(classPeriod: classPeriod)
                .tabItem {
                    Label("Seating", systemImage: selectedTab == 0 ? "square.grid.3x3.fill" : "square.grid.3x3")
                }
                .tag(0)

            // Tab 2: Attendance History
            AttendanceHistoryView(classPeriod: classPeriod)
                .tabItem {
                    Label("History", systemImage: selectedTab == 1 ? "calendar.circle.fill" : "calendar")
                }
                .tag(1)

            // Tab 3: Student Roster
            StudentRosterView(classPeriod: classPeriod)
                .tabItem {
                    Label("Roster", systemImage: selectedTab == 2 ? "person.3.fill" : "person.3")
                }
                .tag(2)

            // Tab 4: Class Settings
            ClassSettingsView(classPeriod: classPeriod)
                .tabItem {
                    Label("Settings", systemImage: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                }
                .tag(3)
        }
        .tint(Theme.Colors.forest)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Class-Specific Settings View

struct ClassSettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var classPeriod: ClassPeriod
    @EnvironmentObject var appStateManager: AppStateManager

    @State private var className: String = ""
    @State private var classSubject: String = ""
    @State private var showingDeleteConfirmation = false
    @State private var showingLayoutList = false
    @State private var showingSeatingRules = false

    var layoutCount: Int {
        (classPeriod.classrooms as? Set<Classroom>)?.count ?? 0
    }

    var studentCount: Int {
        (classPeriod.students as? Set<Student>)?.count ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.ivory
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Class Info Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            ThemeSectionHeader("Class Information")

                            VStack(spacing: Theme.Spacing.sm) {
                                // Class Name field
                                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                                    Text("Class Name")
                                        .font(Theme.Typography.caption(11, weight: .medium))
                                        .foregroundColor(Theme.Colors.slate)
                                        .textCase(.uppercase)
                                        .tracking(0.5)

                                    TextField("Class Name", text: $className)
                                        .font(Theme.Typography.body(16))
                                        .padding(Theme.Spacing.sm)
                                        .background(Color.white)
                                        .cornerRadius(Theme.Radius.sm)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                                                .stroke(Theme.Colors.stone, lineWidth: 1)
                                        )
                                        .onChange(of: className) { _, newValue in
                                            classPeriod.name = newValue
                                            try? viewContext.save()
                                        }
                                }

                                // Subject field
                                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                                    Text("Subject (Optional)")
                                        .font(Theme.Typography.caption(11, weight: .medium))
                                        .foregroundColor(Theme.Colors.slate)
                                        .textCase(.uppercase)
                                        .tracking(0.5)

                                    TextField("Subject", text: $classSubject)
                                        .font(Theme.Typography.body(16))
                                        .padding(Theme.Spacing.sm)
                                        .background(Color.white)
                                        .cornerRadius(Theme.Radius.sm)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                                                .stroke(Theme.Colors.stone, lineWidth: 1)
                                        )
                                        .onChange(of: classSubject) { _, newValue in
                                            classPeriod.subject = newValue
                                            try? viewContext.save()
                                        }
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)

                        // Statistics Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            ThemeSectionHeader("Statistics")

                            VStack(spacing: 0) {
                                statsRow(
                                    icon: "person.3.fill",
                                    label: "Students",
                                    value: "\(studentCount)",
                                    iconColor: Theme.Colors.forest
                                )

                                Divider()
                                    .padding(.leading, 52)

                                statsRow(
                                    icon: "square.grid.3x3.fill",
                                    label: "Layouts",
                                    value: "\(layoutCount)",
                                    iconColor: Theme.Colors.amber
                                )
                            }
                            .background(Color.white)
                            .cornerRadius(Theme.Radius.sm)
                            .themeShadow(Theme.Shadows.subtle)
                        }
                        .padding(.horizontal, Theme.Spacing.md)

                        // Layout Management Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            ThemeSectionHeader("Layouts")

                            Button(action: { showingLayoutList = true }) {
                                HStack(spacing: Theme.Spacing.sm) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Theme.Colors.forest.opacity(0.1))
                                            .frame(width: 36, height: 36)

                                        Image(systemName: "rectangle.3.group.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(Theme.Colors.forest)
                                    }

                                    Text("Manage Layouts")
                                        .font(Theme.Typography.headline(15))
                                        .foregroundColor(Theme.Colors.charcoal)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Theme.Colors.stone)
                                }
                                .padding(Theme.Spacing.sm)
                                .background(Color.white)
                                .cornerRadius(Theme.Radius.sm)
                                .themeShadow(Theme.Shadows.subtle)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, Theme.Spacing.md)

                        // Seating Rules Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            ThemeSectionHeader("Seating Rules", subtitle: "Control who sits together")

                            Button(action: { showingSeatingRules = true }) {
                                HStack(spacing: Theme.Spacing.sm) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Theme.Colors.lavender.opacity(0.2))
                                            .frame(width: 36, height: 36)

                                        Image(systemName: "person.2.wave.2")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(Theme.Colors.purple)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Manage Rules")
                                            .font(Theme.Typography.headline(15))
                                            .foregroundColor(Theme.Colors.charcoal)

                                        if classPeriod.activeRuleCount > 0 {
                                            Text("\(classPeriod.activeRuleCount) active rule\(classPeriod.activeRuleCount == 1 ? "" : "s")")
                                                .font(Theme.Typography.caption(12))
                                                .foregroundColor(Theme.Colors.purple)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Theme.Colors.stone)
                                }
                                .padding(Theme.Spacing.sm)
                                .background(Color.white)
                                .cornerRadius(Theme.Radius.sm)
                                .themeShadow(Theme.Shadows.subtle)
                            }
                            .buttonStyle(.plain)

                            // Helpful tip
                            HStack(spacing: Theme.Spacing.xs) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.Colors.amber)

                                Text("Rules apply when you tap 'Randomize'")
                                    .font(Theme.Typography.caption(11))
                                    .foregroundColor(Theme.Colors.slate)
                            }
                            .padding(.horizontal, Theme.Spacing.xs)
                        }
                        .padding(.horizontal, Theme.Spacing.md)

                        // Display Settings Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            ThemeSectionHeader("Display")

                            VStack(spacing: 0) {
                                // Privacy mode toggle
                                HStack(spacing: Theme.Spacing.sm) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Theme.Colors.slate.opacity(0.1))
                                            .frame(width: 36, height: 36)

                                        Image(systemName: "eye.slash.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(Theme.Colors.slate)
                                    }

                                    Text("Privacy Mode")
                                        .font(Theme.Typography.body(15))
                                        .foregroundColor(Theme.Colors.charcoal)

                                    Spacer()

                                    Toggle("", isOn: $appStateManager.privacyModeEnabled)
                                        .tint(Theme.Colors.forest)
                                }
                                .padding(Theme.Spacing.sm)

                                Divider()
                                    .padding(.leading, 52)

                                // Appearance link
                                NavigationLink(destination: AppearanceSettingsView()) {
                                    HStack(spacing: Theme.Spacing.sm) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Theme.Colors.amber.opacity(0.15))
                                                .frame(width: 36, height: 36)

                                            Image(systemName: "paintbrush.fill")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(Theme.Colors.amber)
                                        }

                                        Text("Appearance")
                                            .font(Theme.Typography.body(15))
                                            .foregroundColor(Theme.Colors.charcoal)

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(Theme.Colors.stone)
                                    }
                                    .padding(Theme.Spacing.sm)
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(Theme.Radius.sm)
                            .themeShadow(Theme.Shadows.subtle)
                        }
                        .padding(.horizontal, Theme.Spacing.md)

                        // Danger Zone
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            ThemeSectionHeader("Danger Zone")

                            Button(action: { showingDeleteConfirmation = true }) {
                                HStack(spacing: Theme.Spacing.sm) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Theme.Colors.danger.opacity(0.1))
                                            .frame(width: 36, height: 36)

                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(Theme.Colors.danger)
                                    }

                                    Text("Delete Class")
                                        .font(Theme.Typography.headline(15, weight: .medium))
                                        .foregroundColor(Theme.Colors.danger)

                                    Spacer()
                                }
                                .padding(Theme.Spacing.sm)
                                .background(Theme.Colors.absentBg)
                                .cornerRadius(Theme.Radius.sm)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.bottom, Theme.Spacing.xl)
                    }
                    .padding(.top, Theme.Spacing.md)
                }
            }
            .navigationTitle("Class Settings")
            .onAppear {
                className = classPeriod.name ?? ""
                classSubject = classPeriod.subject ?? ""
            }
            .sheet(isPresented: $showingLayoutList) {
                NavigationStack {
                    LayoutListView(classPeriod: classPeriod)
                }
            }
            .sheet(isPresented: $showingSeatingRules) {
                SeatingRulesView(classPeriod: classPeriod)
            }
            .confirmationDialog(
                "Delete Class",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteClass()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete \"\(classPeriod.name ?? "this class")\" and all its data. This cannot be undone.")
            }
        }
    }

    private func statsRow(icon: String, label: String, value: String, iconColor: Color) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
            }

            Text(label)
                .font(Theme.Typography.body(15))
                .foregroundColor(Theme.Colors.charcoal)

            Spacer()

            Text(value)
                .font(Theme.Typography.mono(15, weight: .semibold))
                .foregroundColor(Theme.Colors.slate)
        }
        .padding(Theme.Spacing.sm)
    }

    private func deleteClass() {
        viewContext.delete(classPeriod)
        try? viewContext.save()
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let classPeriod = ClassPeriod(context: context)
    classPeriod.id = UUID()
    classPeriod.name = "Period 1"
    classPeriod.subject = "Mathematics"

    return NavigationStack {
        ClassTabView(classPeriod: classPeriod)
            .environment(\.managedObjectContext, context)
            .environmentObject(AppStateManager.shared)
    }
}
