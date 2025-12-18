//
//  ContentView.swift
//  SeatingChart
//
//  Created by Garret Wasden on 11/29/25.
//  Redesigned with Schoolhouse Modern aesthetic
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appStateManager: AppStateManager

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClassPeriod.name, ascending: true)],
        animation: .default)
    private var classPeriods: FetchedResults<ClassPeriod>

    @State private var showingAddClass = false
    @State private var showingStudentPool = false
    @State private var editingClass: ClassPeriod?

    var body: some View {
        NavigationStack {
            ZStack {
                // Warm background
                Theme.Colors.ivory
                    .ignoresSafeArea()

                Group {
                    if classPeriods.isEmpty {
                        emptyStateView
                    } else {
                        classListView
                    }
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    headerView
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    studentPoolButton
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    addClassButton
                    settingsButton
                }
            }
        }
        .sheet(isPresented: $showingAddClass) {
            AddClassSheet()
        }
        .sheet(isPresented: $showingStudentPool) {
            StudentPoolView()
        }
        .sheet(item: $editingClass) { classPeriod in
            EditClassSheet(classPeriod: classPeriod)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 0) {
            Text("SEATING CHART")
                .font(Theme.Typography.caption(10, weight: .bold))
                .tracking(2)
                .foregroundColor(Theme.Colors.forest)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            Spacer()

            // Decorative element
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Theme.Colors.amberLight, lineWidth: 3)
                    .frame(width: 140, height: 140)

                // Middle ring
                Circle()
                    .fill(Theme.Colors.linen)
                    .frame(width: 120, height: 120)

                // Inner circle with icon
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.forest, Theme.Colors.forestLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .themeShadow(Theme.Shadows.forestGlow)

                Image(systemName: "studentdesk")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text("Welcome")
                    .font(Theme.Typography.display(36, weight: .semibold))
                    .foregroundColor(Theme.Colors.charcoal)

                Text("Create your first class to begin\norganizing your classroom")
                    .font(Theme.Typography.body(16))
                    .foregroundColor(Theme.Colors.slate)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button(action: { showingAddClass = true }) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Create First Class")
                        .font(Theme.Typography.headline(17, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    LinearGradient(
                        colors: [Theme.Colors.forest, Theme.Colors.forestLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(Theme.Radius.lg)
                .themeShadow(Theme.Shadows.forestGlow)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Create First Class")
            .accessibilityHint("Tap to create your first class period")

            Spacer()
            Spacer()
        }
        .padding()
    }

    // MARK: - Class List

    private var classListView: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.sm) {
                // Section header
                HStack {
                    ThemeSectionHeader("My Classes", subtitle: "\(classPeriods.count) class\(classPeriods.count == 1 ? "" : "es")")
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xs)

                ForEach(classPeriods) { classPeriod in
                    NavigationLink(destination: ClassTabView(classPeriod: classPeriod)) {
                        ClassPeriodCard(classPeriod: classPeriod)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(action: { editingClass = classPeriod }) {
                            Label("Edit Class", systemImage: "pencil")
                        }

                        Button(role: .destructive, action: { deleteClass(classPeriod) }) {
                            Label("Delete Class", systemImage: "trash")
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
            .padding(.bottom, Theme.Spacing.xl)
        }
    }

    // MARK: - Toolbar Buttons

    private var studentPoolButton: some View {
        Button(action: { showingStudentPool = true }) {
            VStack(spacing: 2) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 16, weight: .medium))
                Text("Students")
                    .font(Theme.Typography.caption(9, weight: .medium))
            }
            .foregroundColor(Theme.Colors.forest)
        }
        .accessibilityLabel("Student Pool")
        .accessibilityHint("View and manage all students across classes")
    }

    private var addClassButton: some View {
        Button(action: { showingAddClass = true }) {
            VStack(spacing: 2) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                Text("Add")
                    .font(Theme.Typography.caption(9, weight: .medium))
            }
            .foregroundColor(Theme.Colors.forest)
        }
        .accessibilityLabel("Add Class")
        .accessibilityHint("Create a new class period")
    }

    private var settingsButton: some View {
        NavigationLink(destination: SettingsView()) {
            VStack(spacing: 2) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .medium))
                Text("Settings")
                    .font(Theme.Typography.caption(9, weight: .medium))
            }
            .foregroundColor(Theme.Colors.forest)
        }
        .accessibilityLabel("Settings")
        .accessibilityHint("Open app settings and preferences")
    }

    // MARK: - Actions

    private func deleteClass(_ classPeriod: ClassPeriod) {
        withAnimation(Theme.Animation.snappy) {
            if let students = classPeriod.students as? Set<Student> {
                for student in students {
                    student.classPeriod = nil
                }
            }

            viewContext.delete(classPeriod)
            try? viewContext.save()
        }
    }
}

// MARK: - Class Period Card

struct ClassPeriodCard: View {
    @ObservedObject var classPeriod: ClassPeriod

    var studentCount: Int {
        (classPeriod.students as? Set<Student>)?.count ?? 0
    }

    var activeLayoutName: String? {
        (classPeriod.classrooms as? Set<Classroom>)?.first(where: { $0.isActive })?.name
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.forest, Theme.Colors.forestMuted],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                // Class name
                Text(classPeriod.name ?? "Unnamed Class")
                    .font(Theme.Typography.display(20, weight: .semibold))
                    .foregroundColor(Theme.Colors.charcoal)

                // Subject if present
                if let subject = classPeriod.subject, !subject.isEmpty {
                    Text(subject)
                        .font(Theme.Typography.body(14))
                        .foregroundColor(Theme.Colors.slate)
                }

                // Stats row
                HStack(spacing: Theme.Spacing.md) {
                    // Student count
                    HStack(spacing: Theme.Spacing.xxs) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 11))
                        Text("\(studentCount)")
                            .font(Theme.Typography.mono(12, weight: .medium))
                    }
                    .foregroundColor(Theme.Colors.slate)

                    // Layout info
                    if let layoutName = activeLayoutName {
                        HStack(spacing: Theme.Spacing.xxs) {
                            Image(systemName: "square.grid.3x3.fill")
                                .font(.system(size: 10))
                            Text(layoutName)
                                .font(Theme.Typography.caption(12))
                        }
                        .foregroundColor(Theme.Colors.amber)
                    }
                }
                .padding(.top, Theme.Spacing.xxs)
            }

            Spacer()

            // Arrow indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.stone)
        }
        .padding(.vertical, Theme.Spacing.md)
        .padding(.horizontal, Theme.Spacing.sm)
        .background(Color.white)
        .cornerRadius(Theme.Radius.md)
        .themeShadow(Theme.Shadows.soft)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(classPeriod.name ?? "Unnamed Class"), \(studentCount) students")
        .accessibilityHint("Double tap to open class")
    }
}

// MARK: - Add Class Sheet

struct AddClassSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var className = ""
    @State private var classSubject = ""
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.ivory
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        // Header illustration
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.amberLight)
                                .frame(width: 80, height: 80)

                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(Theme.Colors.forest)
                        }
                        .padding(.top, Theme.Spacing.lg)

                        // Form fields
                        VStack(spacing: Theme.Spacing.md) {
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text("Class Name")
                                    .font(Theme.Typography.caption(12, weight: .semibold))
                                    .foregroundColor(Theme.Colors.slate)
                                    .textCase(.uppercase)
                                    .tracking(0.5)

                                TextField("e.g., Period 1 Math", text: $className)
                                    .font(Theme.Typography.body(16))
                                    .padding(Theme.Spacing.sm)
                                    .background(Color.white)
                                    .cornerRadius(Theme.Radius.sm)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.Radius.sm)
                                            .stroke(Theme.Colors.stone, lineWidth: 1)
                                    )
                                    .focused($isNameFocused)
                            }

                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text("Subject (Optional)")
                                    .font(Theme.Typography.caption(12, weight: .semibold))
                                    .foregroundColor(Theme.Colors.slate)
                                    .textCase(.uppercase)
                                    .tracking(0.5)

                                TextField("e.g., Mathematics", text: $classSubject)
                                    .font(Theme.Typography.body(16))
                                    .padding(Theme.Spacing.sm)
                                    .background(Color.white)
                                    .cornerRadius(Theme.Radius.sm)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.Radius.sm)
                                            .stroke(Theme.Colors.stone, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)

                        Spacer(minLength: Theme.Spacing.xl)
                    }
                }
            }
            .navigationTitle("New Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.slate)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: createClass) {
                        Text("Create")
                            .font(Theme.Typography.headline(15, weight: .semibold))
                            .foregroundColor(className.isEmpty ? Theme.Colors.stone : Theme.Colors.forest)
                    }
                    .disabled(className.isEmpty)
                }
            }
            .onAppear {
                isNameFocused = true
            }
        }
    }

    private func createClass() {
        let newClass = ClassPeriod(context: viewContext)
        newClass.id = UUID()
        newClass.name = className
        newClass.subject = classSubject.isEmpty ? nil : classSubject
        newClass.createdAt = Date()

        try? viewContext.save()
        dismiss()
    }
}

// MARK: - Edit Class Sheet

struct EditClassSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var classPeriod: ClassPeriod

    @State private var className = ""
    @State private var classSubject = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.ivory
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Form fields
                        VStack(spacing: Theme.Spacing.md) {
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text("Class Name")
                                    .font(Theme.Typography.caption(12, weight: .semibold))
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
                            }

                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text("Subject")
                                    .font(Theme.Typography.caption(12, weight: .semibold))
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
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.lg)

                        // Info section
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            ThemeSectionHeader("Information")

                            VStack(spacing: 0) {
                                infoRow(
                                    icon: "person.2.fill",
                                    label: "Students",
                                    value: "\((classPeriod.students as? Set<Student>)?.count ?? 0)"
                                )

                                Divider()
                                    .padding(.leading, 44)

                                if let createdAt = classPeriod.createdAt {
                                    infoRow(
                                        icon: "calendar",
                                        label: "Created",
                                        value: createdAt.formatted(date: .abbreviated, time: .omitted)
                                    )
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(Theme.Radius.sm)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                    }
                }
            }
            .navigationTitle("Edit Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.slate)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveChanges) {
                        Text("Save")
                            .font(Theme.Typography.headline(15, weight: .semibold))
                            .foregroundColor(className.isEmpty ? Theme.Colors.stone : Theme.Colors.forest)
                    }
                    .disabled(className.isEmpty)
                }
            }
            .onAppear {
                className = classPeriod.name ?? ""
                classSubject = classPeriod.subject ?? ""
            }
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.forest)
                .frame(width: 28)

            Text(label)
                .font(Theme.Typography.body(15))
                .foregroundColor(Theme.Colors.charcoal)

            Spacer()

            Text(value)
                .font(Theme.Typography.body(15))
                .foregroundColor(Theme.Colors.slate)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }

    private func saveChanges() {
        classPeriod.name = className
        classPeriod.subject = classSubject.isEmpty ? nil : classSubject

        try? viewContext.save()
        dismiss()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppStateManager())
}
