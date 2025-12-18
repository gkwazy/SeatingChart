//
//  SeatingRulesView.swift
//  SeatingChart
//
//  Manage seating rules - which students can't sit together
//  Light-hearted, friendly UI for teachers
//

import SwiftUI
import CoreData

struct SeatingRulesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var classPeriod: ClassPeriod

    @State private var showingAddRule = false
    @State private var ruleToEdit: SeatingRule?

    var rules: [SeatingRule] {
        classPeriod.seatingRulesArray
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.ivory
                    .ignoresSafeArea()

                if rules.isEmpty {
                    emptyStateView
                } else {
                    rulesListView
                }
            }
            .navigationTitle("Seating Rules")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.forest)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddRule = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.Colors.forest)
                    }
                }
            }
            .sheet(isPresented: $showingAddRule) {
                AddSeatingRuleView(classPeriod: classPeriod)
            }
            .sheet(item: $ruleToEdit) { rule in
                EditSeatingRuleView(rule: rule)
            }
        }
    }

    // MARK: - Empty State

    @State private var iconFloating = false

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Friendly illustration with floating animation
            ZStack {
                Circle()
                    .fill(Theme.Colors.lavender.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .scaleEffect(iconFloating ? 1.05 : 1.0)

                Circle()
                    .fill(Theme.Colors.lavender.opacity(0.5))
                    .frame(width: 90, height: 90)
                    .scaleEffect(iconFloating ? 0.95 : 1.0)

                Image(systemName: "person.2.wave.2")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(Theme.Colors.purple)
                    .offset(y: iconFloating ? -3 : 3)
            }
            .onAppear {
                withAnimation(Theme.Animation.float) {
                    iconFloating = true
                }
            }

            VStack(spacing: Theme.Spacing.xs) {
                Text("No Seating Rules Yet")
                    .font(Theme.Typography.display(24, weight: .semibold))
                    .foregroundColor(Theme.Colors.charcoal)

                Text("Add rules to keep certain students\napart when randomizing seats")
                    .font(Theme.Typography.body(15))
                    .foregroundColor(Theme.Colors.slate)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button(action: { showingAddRule = true }) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Add First Rule")
                        .font(Theme.Typography.headline(16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.sm)
                .background(
                    LinearGradient(
                        colors: [Theme.Colors.purple, Theme.Colors.lavender],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(Theme.Radius.md)
                .themeShadow(Theme.Shadows.soft)
            }
            .buttonStyle(.plain)
            .padding(.top, Theme.Spacing.sm)

            // Helpful tip
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.amber)

                Text("Tip: Rules are used when you tap 'Randomize'")
                    .font(Theme.Typography.caption(13))
                    .foregroundColor(Theme.Colors.slate)
            }
            .padding(Theme.Spacing.sm)
            .background(Theme.Colors.amberLight.opacity(0.5))
            .cornerRadius(Theme.Radius.sm)
            .padding(.top, Theme.Spacing.lg)
        }
        .padding(Theme.Spacing.xl)
    }

    // MARK: - Rules List

    private var rulesListView: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.sm) {
                // Header info
                HStack {
                    ThemeSectionHeader(
                        "\(rules.count) Rule\(rules.count == 1 ? "" : "s")",
                        subtitle: "Used when randomizing seats"
                    )
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)

                ForEach(rules, id: \.id) { rule in
                    SeatingRuleCard(rule: rule) {
                        ruleToEdit = rule
                    } onToggle: { isActive in
                        toggleRule(rule, isActive: isActive)
                    } onDelete: {
                        deleteRule(rule)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }

                // Add more button at bottom
                Button(action: { showingAddRule = true }) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16, weight: .medium))
                        Text("Add Another Rule")
                            .font(Theme.Typography.headline(14, weight: .medium))
                    }
                    .foregroundColor(Theme.Colors.forest)
                    .padding(Theme.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.forest.opacity(0.08))
                    .cornerRadius(Theme.Radius.sm)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.sm)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
    }

    // MARK: - Actions

    private func toggleRule(_ rule: SeatingRule, isActive: Bool) {
        rule.isActive = isActive
        try? viewContext.save()
    }

    private func deleteRule(_ rule: SeatingRule) {
        withAnimation(Theme.Animation.snappy) {
            viewContext.delete(rule)
            try? viewContext.save()
        }
    }
}

// MARK: - Seating Rule Card

struct SeatingRuleCard: View {
    @ObservedObject var rule: SeatingRule
    let onEdit: () -> Void
    let onToggle: (Bool) -> Void
    let onDelete: () -> Void

    @State private var showingDeleteConfirmation = false
    @State private var isPressed = false
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Theme.Spacing.sm) {
                // Rule type icon
                ZStack {
                    Circle()
                        .fill(rule.ruleTypeEnum.color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: rule.ruleTypeEnum.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(rule.ruleTypeEnum.color)
                }

                // Students involved
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    HStack(spacing: Theme.Spacing.xs) {
                        studentBubble(rule.studentA)

                        Image(systemName: rule.ruleTypeEnum == .keepApart ? "xmark" : "link")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(rule.ruleTypeEnum.color)

                        studentBubble(rule.studentB)
                    }

                    Text(rule.ruleTypeEnum.description)
                        .font(Theme.Typography.caption(11))
                        .foregroundColor(Theme.Colors.slate)
                }

                Spacer()

                // Toggle
                Toggle("", isOn: Binding(
                    get: { rule.isActive },
                    set: { onToggle($0) }
                ))
                .tint(rule.ruleTypeEnum.color)
                .labelsHidden()
            }
            .padding(Theme.Spacing.md)

            // Note if present
            if let note = rule.note, !note.isEmpty {
                HStack {
                    Image(systemName: "note.text")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.slate)

                    Text(note)
                        .font(Theme.Typography.caption(12))
                        .foregroundColor(Theme.Colors.slate)

                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.sm)
            }
        }
        .background(Color.white)
        .cornerRadius(Theme.Radius.md)
        .themeShadow(Theme.Shadows.subtle)
        .opacity(rule.isActive ? 1.0 : 0.6)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .scaleEffect(appeared ? 1.0 : 0.95)
        .opacity(appeared ? 1.0 : 0.0)
        .onTapGesture {
            onEdit()
        }
        .pressEvents {
            withAnimation(Theme.Animation.pop) { isPressed = true }
        } onRelease: {
            withAnimation(Theme.Animation.pop) { isPressed = false }
        }
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit Rule", systemImage: "pencil")
            }

            Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                Label("Delete Rule", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "Delete Rule?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This rule will be permanently deleted.")
        }
        .onAppear {
            withAnimation(Theme.Animation.bouncy.delay(0.1)) {
                appeared = true
            }
        }
    }

    private func studentBubble(_ student: Student?) -> some View {
        HStack(spacing: Theme.Spacing.xxs) {
            if let student = student {
                if let photoData = student.photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Theme.Colors.forest.opacity(0.15))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text(student.initials ?? "?")
                                .font(Theme.Typography.caption(10, weight: .semibold))
                                .foregroundColor(Theme.Colors.forest)
                        )
                }

                Text(student.firstName ?? "Unknown")
                    .font(Theme.Typography.caption(12, weight: .medium))
                    .foregroundColor(Theme.Colors.charcoal)
            }
        }
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, Theme.Spacing.xxs)
        .background(Theme.Colors.mist)
        .cornerRadius(Theme.Radius.full)
    }
}

// MARK: - Add Seating Rule View

struct AddSeatingRuleView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var classPeriod: ClassPeriod

    @State private var selectedStudentA: Student?
    @State private var selectedStudentB: Student?
    @State private var ruleType: SeatingRuleType = .keepApart
    @State private var note: String = ""
    @State private var showingDuplicateAlert = false

    var students: [Student] {
        let studentSet = classPeriod.students as? Set<Student> ?? []
        return studentSet.sorted { ($0.firstName ?? "") < ($1.firstName ?? "") }
    }

    var availableStudentsForB: [Student] {
        students.filter { $0 != selectedStudentA }
    }

    var canSave: Bool {
        selectedStudentA != nil && selectedStudentB != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.ivory
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Header illustration
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.coral.opacity(0.2))
                                .frame(width: 80, height: 80)

                            Image(systemName: "person.2.wave.2")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(Theme.Colors.coral)
                        }
                        .padding(.top, Theme.Spacing.lg)

                        // Rule type picker
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Rule Type")
                                .font(Theme.Typography.caption(12, weight: .semibold))
                                .foregroundColor(Theme.Colors.slate)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            Picker("Rule Type", selection: $ruleType) {
                                ForEach(SeatingRuleType.allCases) { type in
                                    HStack {
                                        Image(systemName: type.icon)
                                        Text(type.displayName)
                                    }
                                    .tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)

                        // Student A picker
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("First Student")
                                .font(Theme.Typography.caption(12, weight: .semibold))
                                .foregroundColor(Theme.Colors.slate)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            StudentPickerButton(
                                selectedStudent: $selectedStudentA,
                                students: students,
                                placeholder: "Select a student"
                            )
                        }
                        .padding(.horizontal, Theme.Spacing.lg)

                        // Visual connector
                        HStack {
                            Spacer()
                            VStack(spacing: Theme.Spacing.xxs) {
                                Image(systemName: ruleType == .keepApart ? "xmark.circle.fill" : "link.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(ruleType.color)

                                Text(ruleType == .keepApart ? "should not sit together" : "should sit together")
                                    .font(Theme.Typography.caption(11))
                                    .foregroundColor(Theme.Colors.slate)
                            }
                            Spacer()
                        }

                        // Student B picker
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Second Student")
                                .font(Theme.Typography.caption(12, weight: .semibold))
                                .foregroundColor(Theme.Colors.slate)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            StudentPickerButton(
                                selectedStudent: $selectedStudentB,
                                students: availableStudentsForB,
                                placeholder: "Select another student"
                            )
                        }
                        .padding(.horizontal, Theme.Spacing.lg)

                        // Optional note
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Note (Optional)")
                                .font(Theme.Typography.caption(12, weight: .semibold))
                                .foregroundColor(Theme.Colors.slate)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            TextField("e.g., They distract each other", text: $note)
                                .font(Theme.Typography.body(15))
                                .padding(Theme.Spacing.sm)
                                .background(Color.white)
                                .cornerRadius(Theme.Radius.sm)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.Radius.sm)
                                        .stroke(Theme.Colors.stone, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, Theme.Spacing.lg)

                        Spacer(minLength: Theme.Spacing.xxl)
                    }
                }
            }
            .navigationTitle("New Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.slate)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRule()
                    }
                    .font(Theme.Typography.headline(15, weight: .semibold))
                    .foregroundColor(canSave ? Theme.Colors.forest : Theme.Colors.stone)
                    .disabled(!canSave)
                }
            }
            .alert("Rule Already Exists", isPresented: $showingDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("A rule between these two students already exists.")
            }
        }
    }

    private func saveRule() {
        guard let studentA = selectedStudentA,
              let studentB = selectedStudentB else { return }

        // Check for duplicates
        if SeatingRule.ruleExists(context: viewContext, studentA: studentA, studentB: studentB, classPeriod: classPeriod) {
            showingDuplicateAlert = true
            return
        }

        _ = SeatingRule.create(
            context: viewContext,
            studentA: studentA,
            studentB: studentB,
            classPeriod: classPeriod,
            type: ruleType,
            note: note.isEmpty ? nil : note
        )

        try? viewContext.save()
        dismiss()
    }
}

// MARK: - Edit Seating Rule View

struct EditSeatingRuleView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var rule: SeatingRule

    @State private var ruleType: SeatingRuleType
    @State private var note: String
    @State private var isActive: Bool

    init(rule: SeatingRule) {
        self.rule = rule
        self._ruleType = State(initialValue: rule.ruleTypeEnum)
        self._note = State(initialValue: rule.note ?? "")
        self._isActive = State(initialValue: rule.isActive)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.ivory
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Students display
                        HStack(spacing: Theme.Spacing.md) {
                            studentCard(rule.studentA)

                            Image(systemName: ruleType.icon)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(ruleType.color)

                            studentCard(rule.studentB)
                        }
                        .padding(Theme.Spacing.lg)
                        .background(Color.white)
                        .cornerRadius(Theme.Radius.md)
                        .themeShadow(Theme.Shadows.subtle)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.lg)

                        // Rule type picker
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Rule Type")
                                .font(Theme.Typography.caption(12, weight: .semibold))
                                .foregroundColor(Theme.Colors.slate)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            Picker("Rule Type", selection: $ruleType) {
                                ForEach(SeatingRuleType.allCases) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)

                        // Active toggle
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            ThemeSectionHeader("Status")

                            HStack {
                                Text("Rule Active")
                                    .font(Theme.Typography.body(15))
                                    .foregroundColor(Theme.Colors.charcoal)

                                Spacer()

                                Toggle("", isOn: $isActive)
                                    .tint(Theme.Colors.forest)
                            }
                            .padding(Theme.Spacing.md)
                            .background(Color.white)
                            .cornerRadius(Theme.Radius.sm)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)

                        // Note field
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Note (Optional)")
                                .font(Theme.Typography.caption(12, weight: .semibold))
                                .foregroundColor(Theme.Colors.slate)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            TextField("Add a note...", text: $note)
                                .font(Theme.Typography.body(15))
                                .padding(Theme.Spacing.sm)
                                .background(Color.white)
                                .cornerRadius(Theme.Radius.sm)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.Radius.sm)
                                        .stroke(Theme.Colors.stone, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                    }
                }
            }
            .navigationTitle("Edit Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.slate)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .font(Theme.Typography.headline(15, weight: .semibold))
                    .foregroundColor(Theme.Colors.forest)
                }
            }
        }
    }

    private func studentCard(_ student: Student?) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            if let student = student {
                if let photoData = student.photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Theme.Colors.forest.opacity(0.15))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(student.initials ?? "?")
                                .font(Theme.Typography.headline(18, weight: .semibold))
                                .foregroundColor(Theme.Colors.forest)
                        )
                }

                Text(student.firstName ?? "Unknown")
                    .font(Theme.Typography.caption(12, weight: .medium))
                    .foregroundColor(Theme.Colors.charcoal)
            }
        }
    }

    private func saveChanges() {
        rule.ruleTypeEnum = ruleType
        rule.note = note.isEmpty ? nil : note
        rule.isActive = isActive

        try? viewContext.save()
        dismiss()
    }
}

// MARK: - Student Picker Button

struct StudentPickerButton: View {
    @Binding var selectedStudent: Student?
    let students: [Student]
    let placeholder: String

    @State private var showingPicker = false

    var body: some View {
        Button(action: { showingPicker = true }) {
            HStack {
                if let student = selectedStudent {
                    if let photoData = student.photoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Theme.Colors.forest.opacity(0.15))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(student.initials ?? "?")
                                    .font(Theme.Typography.caption(12, weight: .semibold))
                                    .foregroundColor(Theme.Colors.forest)
                            )
                    }

                    Text("\(student.firstName ?? "") \(student.lastName ?? "")")
                        .font(Theme.Typography.body(15))
                        .foregroundColor(Theme.Colors.charcoal)
                } else {
                    Image(systemName: "person.circle")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.Colors.stone)

                    Text(placeholder)
                        .font(Theme.Typography.body(15))
                        .foregroundColor(Theme.Colors.slate)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.stone)
            }
            .padding(Theme.Spacing.sm)
            .background(Color.white)
            .cornerRadius(Theme.Radius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                    .stroke(Theme.Colors.stone, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPicker) {
            StudentSelectionSheet(
                selectedStudent: $selectedStudent,
                students: students
            )
        }
    }
}

// MARK: - Student Selection Sheet

struct StudentSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedStudent: Student?
    let students: [Student]

    @State private var searchText = ""

    var filteredStudents: [Student] {
        if searchText.isEmpty {
            return students
        }
        return students.filter { student in
            let fullName = "\(student.firstName ?? "") \(student.lastName ?? "")"
            return fullName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.ivory
                    .ignoresSafeArea()

                if students.isEmpty {
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.Colors.slate)

                        Text("No Students")
                            .font(Theme.Typography.headline(17))
                            .foregroundColor(Theme.Colors.charcoal)

                        Text("Add students to your class first")
                            .font(Theme.Typography.body(14))
                            .foregroundColor(Theme.Colors.slate)
                    }
                } else {
                    List {
                        ForEach(filteredStudents) { student in
                            Button(action: {
                                selectedStudent = student
                                dismiss()
                            }) {
                                HStack(spacing: Theme.Spacing.sm) {
                                    if let photoData = student.photoData, let uiImage = UIImage(data: photoData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 44, height: 44)
                                            .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Theme.Colors.forest.opacity(0.15))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Text(student.initials ?? "?")
                                                    .font(Theme.Typography.headline(16, weight: .semibold))
                                                    .foregroundColor(Theme.Colors.forest)
                                            )
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(student.firstName ?? "") \(student.lastName ?? "")")
                                            .font(Theme.Typography.headline(15))
                                            .foregroundColor(Theme.Colors.charcoal)

                                        if let studentID = student.studentID, !studentID.isEmpty {
                                            Text("ID: \(studentID)")
                                                .font(Theme.Typography.caption(12))
                                                .foregroundColor(Theme.Colors.slate)
                                        }
                                    }

                                    Spacer()

                                    if selectedStudent == student {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(Theme.Colors.forest)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search students")
                }
            }
            .navigationTitle("Select Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.forest)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let classPeriod = ClassPeriod(context: context)
    classPeriod.id = UUID()
    classPeriod.name = "Period 1"

    return SeatingRulesView(classPeriod: classPeriod)
        .environment(\.managedObjectContext, context)
}
