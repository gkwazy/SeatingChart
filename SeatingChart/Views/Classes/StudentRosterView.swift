//
//  StudentRosterView.swift
//  SeatingChart
//
//  Created on 2025-11-29.
//

import SwiftUI
import PhotosUI
import CoreData

struct StudentRosterView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var classPeriod: ClassPeriod

    @State private var showingAddStudent = false
    @State private var searchText = ""

    var students: [Student] {
        let studentSet = classPeriod.students as? Set<Student> ?? []
        return studentSet.sorted { ($0.lastName ?? "") < ($1.lastName ?? "") }
    }

    var filteredStudents: [Student] {
        if searchText.isEmpty {
            return students
        } else {
            return students.filter { student in
                let fullName = "\(student.firstName ?? "") \(student.lastName ?? "")"
                return fullName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        List {
            ForEach(filteredStudents) { student in
                NavigationLink(destination: StudentDetailView(student: student)) {
                    StudentRow(student: student)
                }
            }
            .onDelete(perform: deleteStudents)
        }
        .searchable(text: $searchText, prompt: "Search students")
        .navigationTitle("Student Roster")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddStudent = true }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Student")
                .accessibilityHint("Add a new student to this class")
            }
        }
        .sheet(isPresented: $showingAddStudent) {
            AddStudentView(classPeriod: classPeriod, isPresented: $showingAddStudent)
        }
        .overlay {
            if students.isEmpty {
                VStack(spacing: Theme.Spacing.md) {
                    // Friendly illustration
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.peach.opacity(0.2))
                            .frame(width: 100, height: 100)

                        Image(systemName: "person.3.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(Theme.Colors.coral)
                    }

                    VStack(spacing: Theme.Spacing.xs) {
                        Text("No Students Yet")
                            .font(Theme.Typography.display(20, weight: .semibold))
                            .foregroundColor(Theme.Colors.charcoal)

                        Text("Add your first student to get started!")
                            .font(Theme.Typography.body(15))
                            .foregroundColor(Theme.Colors.slate)
                    }

                    Button(action: { showingAddStudent = true }) {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Add Student")
                                .font(Theme.Typography.headline(15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Colors.forest)
                        .cornerRadius(Theme.Radius.full)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add Student")
                    .accessibilityHint("Add your first student to this class")
                    .padding(.top, Theme.Spacing.xs)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.Colors.ivory)
            }
        }
    }

    private func deleteStudents(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredStudents[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                #if DEBUG
                print("Error deleting student: \(error.localizedDescription)")
                #endif
            }
        }
    }
}

struct StudentRow: View {
    let student: Student
    @Environment(\.managedObjectContext) private var viewContext

    private var absenceCount: Int {
        let records = student.attendanceRecords as? Set<AttendanceRecord> ?? []
        return records.filter { $0.attendanceStatus == .absent }.count
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Photo
            if let photoData = student.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Theme.Colors.forest.opacity(0.2), lineWidth: 2))
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

            VStack(alignment: .leading, spacing: 4) {
                Text("\(student.firstName ?? "") \(student.lastName ?? "")")
                    .font(Theme.Typography.headline(16))
                    .foregroundColor(Theme.Colors.charcoal)

                HStack(spacing: Theme.Spacing.xs) {
                    if let studentID = student.studentID, !studentID.isEmpty {
                        Text("ID: \(studentID)")
                            .font(Theme.Typography.caption(12))
                            .foregroundColor(Theme.Colors.slate)
                    }

                    // Show absence count if any
                    if absenceCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 10))
                            Text("\(absenceCount) absence\(absenceCount == 1 ? "" : "s")")
                                .font(Theme.Typography.caption(11, weight: .medium))
                        }
                        .foregroundColor(Theme.Colors.coral)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(student.firstName ?? "") \(student.lastName ?? "")")
        .accessibilityValue(absenceCount > 0 ? "\(absenceCount) absence\(absenceCount == 1 ? "" : "s")" : "No absences")
    }
}

struct AddStudentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var classPeriod: ClassPeriod
    @Binding var isPresented: Bool

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var studentID = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Student Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Student ID (Optional)", text: $studentID)
                }

                Section(header: Text("Photo")) {
                    HStack {
                        if let photoData = photoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Text(photoData == nil ? "Add Photo" : "Change Photo")
                        }
                    }
                }
            }
            .navigationTitle("Add Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addStudent()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
    }

    private func addStudent() {
        let student = Student(context: viewContext)
        student.id = UUID()
        student.firstName = firstName
        student.lastName = lastName
        student.studentID = studentID.isEmpty ? nil : studentID
        student.photoData = photoData
        student.classPeriod = classPeriod

        do {
            try viewContext.save()
            isPresented = false
        } catch {
            #if DEBUG
            print("Error saving student: \(error.localizedDescription)")
            #endif
        }
    }
}

struct StudentDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var student: Student

    @State private var isEditing = false

    var attendanceRecords: [AttendanceRecord] {
        let records = student.attendanceRecords as? Set<AttendanceRecord> ?? []
        return records.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    var attendanceStats: (present: Int, absent: Int, tardy: Int, total: Int) {
        var present = 0
        var absent = 0
        var tardy = 0

        for record in attendanceRecords {
            switch record.attendanceStatus {
            case .present: present += 1
            case .absent: absent += 1
            case .tardy: tardy += 1
            }
        }
        return (present, absent, tardy, present + absent + tardy)
    }

    var absentDates: [Date] {
        attendanceRecords
            .filter { $0.attendanceStatus == .absent }
            .compactMap { $0.date }
            .sorted(by: >)
    }

    var tardyDates: [Date] {
        attendanceRecords
            .filter { $0.attendanceStatus == .tardy }
            .compactMap { $0.date }
            .sorted(by: >)
    }

    var seatingRules: [SeatingRule] {
        guard let classPeriod = student.classPeriod else { return [] }
        return student.allSeatingRules.filter { $0.classPeriod == classPeriod && $0.isActive }
    }

    var body: some View {
        ZStack {
            Theme.Colors.ivory
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header with photo
                    studentHeader

                    // Quick Stats Cards
                    attendanceStatsCards

                    // Absent Dates (if any)
                    if !absentDates.isEmpty {
                        absentDatesSection
                    }

                    // Tardy Dates (if any)
                    if !tardyDates.isEmpty {
                        tardyDatesSection
                    }

                    // Seating Rules
                    if !seatingRules.isEmpty {
                        seatingRulesSection
                    }

                    // Full Attendance History
                    attendanceHistorySection
                }
                .padding(.bottom, Theme.Spacing.xxl)
            }
        }
        .navigationTitle("Student Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    isEditing = true
                }
                .foregroundColor(Theme.Colors.forest)
            }
        }
        .sheet(isPresented: $isEditing) {
            EditStudentView(student: student, isPresented: $isEditing)
        }
    }

    // MARK: - Student Header

    private var studentHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Photo
            if let photoData = student.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Theme.Colors.forest, lineWidth: 3))
                    .shadow(color: Theme.Colors.forest.opacity(0.3), radius: 10, x: 0, y: 4)
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.forest.opacity(0.2), Theme.Colors.forest.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(student.initials ?? "?")
                            .font(Theme.Typography.display(36, weight: .semibold))
                            .foregroundColor(Theme.Colors.forest)
                    )
                    .shadow(color: Theme.Colors.forest.opacity(0.2), radius: 8, x: 0, y: 4)
            }

            // Name
            Text("\(student.firstName ?? "") \(student.lastName ?? "")")
                .font(Theme.Typography.display(24, weight: .semibold))
                .foregroundColor(Theme.Colors.charcoal)

            // Info pills
            HStack(spacing: Theme.Spacing.sm) {
                if let studentID = student.studentID, !studentID.isEmpty {
                    infoPill(icon: "number", text: studentID)
                }

                if let classPeriod = student.classPeriod {
                    infoPill(icon: "clock", text: classPeriod.name ?? "Class")
                }
            }
        }
        .padding(.top, Theme.Spacing.lg)
    }

    private func infoPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
            Text(text)
                .font(Theme.Typography.caption(12, weight: .medium))
        }
        .foregroundColor(Theme.Colors.slate)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 4)
        .background(Theme.Colors.mist)
        .cornerRadius(Theme.Radius.full)
    }

    // MARK: - Attendance Stats Cards

    private var attendanceStatsCards: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ThemeSectionHeader("Attendance Overview")
                .padding(.horizontal, Theme.Spacing.md)

            HStack(spacing: Theme.Spacing.sm) {
                // Present
                statCard(
                    count: attendanceStats.present,
                    label: "Present",
                    icon: "checkmark.circle.fill",
                    color: Theme.Colors.success,
                    bgColor: Theme.Colors.presentBg
                )

                // Absent
                statCard(
                    count: attendanceStats.absent,
                    label: "Absent",
                    icon: "xmark.circle.fill",
                    color: Theme.Colors.coral,
                    bgColor: Theme.Colors.absentBg
                )

                // Tardy
                statCard(
                    count: attendanceStats.tardy,
                    label: "Tardy",
                    icon: "clock.fill",
                    color: Theme.Colors.amber,
                    bgColor: Theme.Colors.tardyBg
                )
            }
            .padding(.horizontal, Theme.Spacing.md)

            // Attendance rate bar
            if attendanceStats.total > 0 {
                attendanceRateBar
                    .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }

    private func statCard(count: Int, label: String, icon: String, color: Color, bgColor: Color) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)

            Text("\(count)")
                .font(Theme.Typography.display(28, weight: .bold))
                .foregroundColor(Theme.Colors.charcoal)

            Text(label)
                .font(Theme.Typography.caption(11, weight: .medium))
                .foregroundColor(Theme.Colors.slate)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
        .background(bgColor)
        .cornerRadius(Theme.Radius.md)
    }

    private var attendanceRateBar: some View {
        let rate = Double(attendanceStats.present) / Double(attendanceStats.total)
        let percentage = Int(rate * 100)

        return VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text("Attendance Rate")
                    .font(Theme.Typography.caption(12, weight: .medium))
                    .foregroundColor(Theme.Colors.slate)
                Spacer()
                Text("\(percentage)%")
                    .font(Theme.Typography.headline(14, weight: .bold))
                    .foregroundColor(rate >= 0.9 ? Theme.Colors.success : (rate >= 0.8 ? Theme.Colors.amber : Theme.Colors.coral))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.Colors.stone.opacity(0.3))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(rate >= 0.9 ? Theme.Colors.success : (rate >= 0.8 ? Theme.Colors.amber : Theme.Colors.coral))
                        .frame(width: geometry.size.width * CGFloat(rate), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(Theme.Spacing.sm)
        .background(Color.white)
        .cornerRadius(Theme.Radius.sm)
        .themeShadow(Theme.Shadows.subtle)
    }

    // MARK: - Absent Dates Section

    private var absentDatesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ThemeSectionHeader("Absent Dates", subtitle: "\(absentDates.count) day\(absentDates.count == 1 ? "" : "s")")
                .padding(.horizontal, Theme.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(absentDates.prefix(10), id: \.self) { date in
                        dateChip(date: date, color: Theme.Colors.coral, bgColor: Theme.Colors.absentBg)
                    }

                    if absentDates.count > 10 {
                        Text("+\(absentDates.count - 10) more")
                            .font(Theme.Typography.caption(11, weight: .medium))
                            .foregroundColor(Theme.Colors.slate)
                            .padding(.horizontal, Theme.Spacing.sm)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }

    // MARK: - Tardy Dates Section

    private var tardyDatesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ThemeSectionHeader("Tardy Dates", subtitle: "\(tardyDates.count) day\(tardyDates.count == 1 ? "" : "s")")
                .padding(.horizontal, Theme.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(tardyDates.prefix(10), id: \.self) { date in
                        dateChip(date: date, color: Theme.Colors.amber, bgColor: Theme.Colors.tardyBg)
                    }

                    if tardyDates.count > 10 {
                        Text("+\(tardyDates.count - 10) more")
                            .font(Theme.Typography.caption(11, weight: .medium))
                            .foregroundColor(Theme.Colors.slate)
                            .padding(.horizontal, Theme.Spacing.sm)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }

    private func dateChip(date: Date, color: Color, bgColor: Color) -> some View {
        VStack(spacing: 2) {
            Text(date.formatted(.dateTime.month(.abbreviated)))
                .font(Theme.Typography.caption(10, weight: .medium))
                .foregroundColor(color)

            Text(date.formatted(.dateTime.day()))
                .font(Theme.Typography.headline(16, weight: .bold))
                .foregroundColor(Theme.Colors.charcoal)
        }
        .frame(width: 48, height: 48)
        .background(bgColor)
        .cornerRadius(Theme.Radius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Seating Rules Section

    private var seatingRulesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ThemeSectionHeader("Seating Rules", subtitle: "Applied during randomization")
                .padding(.horizontal, Theme.Spacing.md)

            VStack(spacing: Theme.Spacing.xs) {
                ForEach(seatingRules, id: \.id) { rule in
                    ruleRow(rule: rule)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private func ruleRow(rule: SeatingRule) -> some View {
        let otherStudent = rule.otherStudent(from: student)

        return HStack(spacing: Theme.Spacing.sm) {
            // Rule type icon
            ZStack {
                Circle()
                    .fill(rule.ruleTypeEnum.color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: rule.ruleTypeEnum.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(rule.ruleTypeEnum.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.ruleTypeEnum.displayName)
                    .font(Theme.Typography.headline(14, weight: .medium))
                    .foregroundColor(Theme.Colors.charcoal)

                Text("with \(otherStudent?.firstName ?? "Unknown")")
                    .font(Theme.Typography.caption(12))
                    .foregroundColor(Theme.Colors.slate)
            }

            Spacer()

            // Other student's avatar
            if let other = otherStudent {
                if let photoData = other.photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Theme.Colors.slate.opacity(0.15))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(other.initials ?? "?")
                                .font(Theme.Typography.caption(11, weight: .semibold))
                                .foregroundColor(Theme.Colors.slate)
                        )
                }
            }
        }
        .padding(Theme.Spacing.sm)
        .background(Color.white)
        .cornerRadius(Theme.Radius.sm)
        .themeShadow(Theme.Shadows.subtle)
    }

    // MARK: - Attendance History Section

    private var attendanceHistorySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ThemeSectionHeader("Attendance History")
                .padding(.horizontal, Theme.Spacing.md)

            if attendanceRecords.isEmpty {
                // Friendly empty state
                VStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.sky.opacity(0.15))
                            .frame(width: 64, height: 64)

                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(Theme.Colors.sky)
                    }

                    Text("No Records Yet")
                        .font(Theme.Typography.headline(16, weight: .semibold))
                        .foregroundColor(Theme.Colors.charcoal)

                    Text("Attendance will appear here once you start taking roll")
                        .font(Theme.Typography.body(14))
                        .foregroundColor(Theme.Colors.slate)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.xl)
                .background(Color.white)
                .cornerRadius(Theme.Radius.md)
                .padding(.horizontal, Theme.Spacing.md)
            } else {
                // Grouped by month
                let grouped = Dictionary(grouping: attendanceRecords) { record -> String in
                    guard let date = record.date else { return "Unknown" }
                    return date.formatted(.dateTime.month(.wide).year())
                }

                let sortedKeys = grouped.keys.sorted { key1, key2 in
                    guard let firstRecord1 = grouped[key1]?.first?.date,
                          let firstRecord2 = grouped[key2]?.first?.date else { return false }
                    return firstRecord1 > firstRecord2
                }

                VStack(spacing: Theme.Spacing.md) {
                    ForEach(sortedKeys, id: \.self) { monthYear in
                        monthSection(title: monthYear, records: grouped[monthYear] ?? [])
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }

    private func monthSection(title: String, records: [AttendanceRecord]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Typography.caption(11, weight: .semibold))
                .foregroundColor(Theme.Colors.slate)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, Theme.Spacing.sm)

            VStack(spacing: 0) {
                ForEach(records.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }, id: \.id) { record in
                    attendanceRecordRow(record: record)

                    if record != records.sorted(by: { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }).last {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(Theme.Radius.sm)
            .themeShadow(Theme.Shadows.subtle)
        }
    }

    private func attendanceRecordRow(record: AttendanceRecord) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Status icon
            ZStack {
                Circle()
                    .fill(statusBackgroundColor(for: record.attendanceStatus))
                    .frame(width: 36, height: 36)

                Image(systemName: record.attendanceStatus.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(statusColor(for: record.attendanceStatus))
            }

            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(record.date?.formatted(.dateTime.weekday(.wide)) ?? "Unknown")
                    .font(Theme.Typography.headline(14))
                    .foregroundColor(Theme.Colors.charcoal)

                Text(record.date?.formatted(.dateTime.day().month(.abbreviated)) ?? "")
                    .font(Theme.Typography.caption(12))
                    .foregroundColor(Theme.Colors.slate)
            }

            Spacer()

            // Status badge
            Text(record.attendanceStatus.displayName)
                .font(Theme.Typography.caption(11, weight: .semibold))
                .foregroundColor(statusColor(for: record.attendanceStatus))
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, 4)
                .background(statusBackgroundColor(for: record.attendanceStatus))
                .cornerRadius(Theme.Radius.full)
        }
        .padding(Theme.Spacing.sm)
    }

    private func statusColor(for status: AttendanceStatus) -> Color {
        switch status {
        case .present: return Theme.Colors.success
        case .absent: return Theme.Colors.coral
        case .tardy: return Theme.Colors.amber
        }
    }

    private func statusBackgroundColor(for status: AttendanceStatus) -> Color {
        switch status {
        case .present: return Theme.Colors.presentBg
        case .absent: return Theme.Colors.absentBg
        case .tardy: return Theme.Colors.tardyBg
        }
    }
}

struct AttendanceStatView: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 60)
    }
}

struct EditStudentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var student: Student
    @Binding var isPresented: Bool

    @State private var firstName: String
    @State private var lastName: String
    @State private var studentID: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    init(student: Student, isPresented: Binding<Bool>) {
        self.student = student
        self._isPresented = isPresented
        self._firstName = State(initialValue: student.firstName ?? "")
        self._lastName = State(initialValue: student.lastName ?? "")
        self._studentID = State(initialValue: student.studentID ?? "")
        self._photoData = State(initialValue: student.photoData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Student Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Student ID (Optional)", text: $studentID)
                }

                Section(header: Text("Photo")) {
                    HStack {
                        if let photoData = photoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Text(photoData == nil ? "Add Photo" : "Change Photo")
                        }
                    }
                }
            }
            .navigationTitle("Edit Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
    }

    private func saveChanges() {
        student.firstName = firstName
        student.lastName = lastName
        student.studentID = studentID.isEmpty ? nil : studentID
        student.photoData = photoData

        do {
            try viewContext.save()
            isPresented = false
        } catch {
            #if DEBUG
            print("Error saving changes: \(error.localizedDescription)")
            #endif
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let classPeriod = ClassPeriod(context: context)
    classPeriod.id = UUID()
    classPeriod.name = "Period 1"
    classPeriod.subject = "Math"

    return NavigationStack {
        StudentRosterView(classPeriod: classPeriod)
            .environment(\.managedObjectContext, context)
    }
}
