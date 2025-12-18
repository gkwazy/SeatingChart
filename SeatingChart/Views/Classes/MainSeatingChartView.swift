//
//  MainSeatingChartView.swift
//  SeatingChart
//
//  Primary view shown when opening a class
//  Shows seating chart with action buttons at top
//  Redesigned with Schoolhouse Modern aesthetic
//
//  Refactored: Components extracted to separate files:
//  - ThemedSeatingCanvas.swift
//  - ThemedDeskView.swift
//  - ThemedActionPill.swift
//  - ThemedStudentAssignmentSheet.swift
//  - LayoutPickerSheet.swift
//

import SwiftUI
import CoreData

struct MainSeatingChartView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var classPeriod: ClassPeriod
    @EnvironmentObject var appStateManager: AppStateManager

    // View state
    @State private var desks: [Desk] = []
    @State private var showPhotos = false
    @State private var attendanceDate = Date()
    @State private var attendanceStatus: [UUID: AttendanceStatus] = [:]
    @State private var isTakingAttendance = false
    @State private var hasTodaysAttendance = false
    @State private var showingPastAttendanceAlert = false

    // Navigation
    @State private var showingRoster = false
    @State private var showingEditLayout = false
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var showingRandomConfirmation = false
    @State private var showingLayoutPicker = false
    @State private var showingSeatingRules = false

    // Student assignment
    @State private var selectedDesk: Desk?

    // Haptic feedback - lazily initialized to avoid memory leak
    private var hapticFeedback: UIImpactFeedbackGenerator {
        UIImpactFeedbackGenerator(style: .medium)
    }
    private var hapticSuccess: UINotificationFeedbackGenerator {
        UINotificationFeedbackGenerator()
    }

    // Room settings
    @State private var roomSize = CGSize(width: 1000, height: 800)

    // MARK: - Computed Properties

    var activeClassroom: Classroom? {
        (classPeriod.classrooms as? Set<Classroom>)?.first(where: { $0.isActive }) ??
        (classPeriod.classrooms as? Set<Classroom>)?.first
    }

    var students: [Student] {
        let studentSet = classPeriod.students as? Set<Student> ?? []
        return studentSet.sorted { ($0.lastName ?? "") < ($1.lastName ?? "") }
    }

    var unassignedStudents: [Student] {
        let assignedIDs = Set(desks.flatMap { $0.assignedStudentIDs })
        return students.filter { student in
            guard let id = student.id else { return true }
            return !assignedIDs.contains(id)
        }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Theme.Colors.ivory
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    actionButtonsBar

                    if let _ = activeClassroom {
                        ThemedSeatingCanvas(
                            desks: desks,
                            students: students,
                            isTakingAttendance: isTakingAttendance,
                            attendanceStatus: attendanceStatus,
                            showPhotos: showPhotos,
                            privacyMode: appStateManager.privacyModeEnabled,
                            hasTodaysAttendance: hasTodaysAttendance,
                            onDeskTap: handleDeskTap,
                            availableSize: CGSize(
                                width: geometry.size.width,
                                height: geometry.size.height - 80
                            )
                        )
                        .clipped()
                    } else {
                        noLayoutView
                            .frame(maxHeight: .infinity)
                    }
                }

                // Toast overlay
                if showToast, let message = toastMessage {
                    VStack {
                        Spacer()
                        toastView(message: message)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(Theme.Animation.snappy, value: showToast)
                }
            }
        }
        .navigationTitle(classPeriod.name ?? "Class")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                photoToggleButton
            }
        }
        .sheet(isPresented: $showingRoster) {
            NavigationStack {
                StudentRosterView(classPeriod: classPeriod)
            }
        }
        .sheet(isPresented: $showingEditLayout, onDismiss: {
            loadDesks()
        }) {
            if let classroom = activeClassroom {
                NavigationStack {
                    EnhancedLayoutEditorView(classroom: classroom)
                }
            } else {
                NavigationStack {
                    LayoutListView(classPeriod: classPeriod)
                }
            }
        }
        .sheet(item: $selectedDesk) { desk in
            ThemedStudentAssignmentSheet(
                desk: desk,
                students: unassignedStudents,
                assignedStudent: studentForDesk(desk),
                onAssign: { student in
                    assignStudent(student, to: desk)
                },
                onUnassign: {
                    unassignStudent(from: desk)
                }
            )
        }
        .alert("Randomize Seating?", isPresented: $showingRandomConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Randomize") {
                randomizeSeating()
            }
        } message: {
            Text("This will randomly reassign all \(students.count) students to desks.")
        }
        .sheet(isPresented: $showingLayoutPicker) {
            LayoutPickerSheet(
                classPeriod: classPeriod,
                currentLayout: activeClassroom,
                onSelectLayout: { layout in
                    switchToLayout(layout)
                },
                onEditLayout: {
                    showingLayoutPicker = false
                    showingEditLayout = true
                }
            )
        }
        .sheet(isPresented: $showingSeatingRules) {
            SeatingRulesView(classPeriod: classPeriod)
        }
        .onAppear {
            loadDesks()
            loadTodaysAttendance()
        }
        .onDisappear {
            if isTakingAttendance && !attendanceStatus.isEmpty {
                autoSaveAttendance()
            }
        }
    }

    // MARK: - Photo Toggle Button

    private var photoToggleButton: some View {
        Button(action: { showPhotos.toggle() }) {
            HStack(spacing: 4) {
                Image(systemName: showPhotos ? "photo.fill" : "photo")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(showPhotos ? Theme.Colors.forest : Theme.Colors.slate)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(showPhotos ? Theme.Colors.forest.opacity(0.1) : Theme.Colors.mist)
            .cornerRadius(Theme.Radius.sm)
        }
        .accessibilityLabel(showPhotos ? "Hide photos" : "Show photos")
    }

    // MARK: - Action Buttons Bar

    private var actionButtonsBar: some View {
        HStack {
            Spacer()
            HStack(spacing: Theme.Spacing.sm) {
                if !isTakingAttendance {
                    ThemedActionPill(
                        title: "Attendance",
                        icon: "checkmark.circle.fill",
                        style: .success,
                        action: { startTakingAttendance() }
                    )

                    ThemedActionPill(
                        title: "Random",
                        icon: "shuffle",
                        style: .primary,
                        action: { showingRandomConfirmation = true }
                    )
                } else {
                    ThemedActionPill(
                        title: "Save",
                        icon: "square.and.arrow.down.fill",
                        style: .primary,
                        action: saveAttendance
                    )

                    ThemedActionPill(
                        title: "Cancel",
                        icon: "xmark.circle.fill",
                        style: .danger,
                        action: cancelAttendance
                    )
                }
            }
            Spacer()
        }
        .padding(.vertical, Theme.Spacing.md)
        .background(
            Color.white
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - No Layout View

    private var noLayoutView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.amberLight)
                    .frame(width: 100, height: 100)

                Image(systemName: "square.grid.3x3.slash")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(Theme.Colors.amber)
            }

            VStack(spacing: Theme.Spacing.xs) {
                Text("No Layout Created")
                    .font(Theme.Typography.display(24, weight: .semibold))
                    .foregroundColor(Theme.Colors.charcoal)

                Text("Create a classroom layout to get started")
                    .font(Theme.Typography.body(15))
                    .foregroundColor(Theme.Colors.slate)
            }

            Button(action: { showingEditLayout = true }) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Create Layout")
                        .font(Theme.Typography.headline(16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.sm)
                .background(
                    LinearGradient(
                        colors: [Theme.Colors.forest, Theme.Colors.forestLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(Theme.Radius.md)
                .themeShadow(Theme.Shadows.forestGlow)
            }
            .buttonStyle(.plain)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No layout created. Tap to create a classroom layout.")
    }

    // MARK: - Toast View

    private func toastView(message: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.Colors.success)

            Text(message)
                .font(Theme.Typography.headline(14, weight: .medium))
                .foregroundColor(Theme.Colors.charcoal)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Color.white)
        .cornerRadius(Theme.Radius.full)
        .themeShadow(Theme.Shadows.medium)
        .padding(.bottom, Theme.Spacing.xxl)
        .accessibilityLabel(message)
    }

    // MARK: - Helper Functions

    private func loadDesks() {
        guard let classroom = activeClassroom,
              let deskData = classroom.deskPositions,
              let loadedDesks = try? JSONDecoder().decode([Desk].self, from: deskData) else {
            desks = []
            return
        }
        desks = loadedDesks
    }

    private func studentForDesk(_ desk: Desk) -> Student? {
        guard let studentID = desk.assignedStudentIDs.first else { return nil }
        return students.first(where: { $0.id == studentID })
    }

    private func statusForDesk(_ desk: Desk) -> AttendanceStatus {
        guard let student = studentForDesk(desk),
              let studentID = student.id else {
            return .present
        }
        return attendanceStatus[studentID] ?? .present
    }

    private func handleDeskTap(_ desk: Desk) {
        if isTakingAttendance {
            guard let student = studentForDesk(desk),
                  let studentID = student.id else {
                return
            }

            let currentStatus = attendanceStatus[studentID] ?? .present
            attendanceStatus[studentID] = currentStatus.next

            hapticFeedback.impactOccurred()
        } else {
            hapticFeedback.impactOccurred()
            selectedDesk = desk
        }
    }

    private func loadTodaysAttendance() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request: NSFetchRequest<AttendanceRecord> = AttendanceRecord.fetchRequest()
        request.predicate = NSPredicate(
            format: "classPeriod == %@ AND date >= %@ AND date < %@",
            classPeriod, startOfDay as NSDate, endOfDay as NSDate
        )

        if let records = try? viewContext.fetch(request) {
            attendanceStatus.removeAll()
            for record in records {
                if let studentId = record.student?.id {
                    attendanceStatus[studentId] = record.attendanceStatus
                }
            }
            hasTodaysAttendance = !records.isEmpty
        } else {
            hasTodaysAttendance = false
        }
    }

    private func startTakingAttendance() {
        isTakingAttendance = true

        for student in students {
            if let id = student.id, attendanceStatus[id] == nil {
                attendanceStatus[id] = .present
            }
        }
    }

    private func cancelAttendance() {
        isTakingAttendance = false
        loadTodaysAttendance()
    }

    private func saveAttendance() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: attendanceDate)

        for (studentId, status) in attendanceStatus {
            if let student = students.first(where: { $0.id == studentId }) {
                _ = AttendanceRecord.createOrUpdate(
                    context: viewContext,
                    student: student,
                    classPeriod: classPeriod,
                    date: startOfDay,
                    status: status
                )
            }
        }

        do {
            try viewContext.save()
            hapticSuccess.notificationOccurred(.success)
            isTakingAttendance = false
            hasTodaysAttendance = true
            showToast(message: "Attendance saved")
        } catch {
            hapticSuccess.notificationOccurred(.error)
            showToast(message: "Error saving attendance")
        }
    }

    private func assignStudent(_ student: Student, to desk: Desk) {
        guard let deskIndex = desks.firstIndex(where: { $0.id == desk.id }),
              let studentID = student.id else { return }

        for i in desks.indices {
            desks[i].assignedStudentIDs.removeAll { $0 == studentID }
        }

        desks[deskIndex].assignedStudentIDs.append(studentID)
        saveDesks()
    }

    private func unassignStudent(from desk: Desk) {
        guard let deskIndex = desks.firstIndex(where: { $0.id == desk.id }) else { return }
        desks[deskIndex].assignedStudentIDs.removeAll()
        saveDesks()
    }

    // MARK: - Randomize Seating
    // Coordinate System Note: iOS Y increases DOWNWARD
    // "Front of room" = BOTTOM of screen = HIGH Y values
    // "Back of room" = TOP of screen = LOW Y values
    // Front-to-back fill: Sort by Y descending (high Y first)

    private func randomizeSeating() {
        let rules = SeatingRule.fetchActiveRules(context: viewContext, classPeriod: classPeriod)
        let keepApartRules = rules.filter { $0.ruleTypeEnum == .keepApart }
        let keepTogetherRules = rules.filter { $0.ruleTypeEnum == .keepTogether }

        // Clear all desk assignments
        for i in desks.indices {
            desks[i].assignedStudentIDs.removeAll()
        }

        // Sort desks: front (high Y) to back (low Y), left to right
        let sortedDeskIndices = desks.indices.sorted { i1, i2 in
            if desks[i1].position.y != desks[i2].position.y {
                return desks[i1].position.y > desks[i2].position.y
            }
            return desks[i1].position.x < desks[i2].position.x
        }

        var shuffledDeskIndices = sortedDeskIndices.shuffled()
        let adjacencyMap = buildDeskAdjacencyMap()

        var remainingStudents = students.shuffled()
        var placedStudentIDs = Set<UUID>()

        // STEP 1: Place keep-together pairs first
        for rule in keepTogetherRules {
            guard let studentA = rule.studentA,
                  let studentB = rule.studentB,
                  let idA = studentA.id,
                  let idB = studentB.id,
                  !placedStudentIDs.contains(idA),
                  !placedStudentIDs.contains(idB) else { continue }

            for deskIndex in shuffledDeskIndices {
                guard desks[deskIndex].assignedStudentIDs.isEmpty else { continue }
                guard canPlaceStudent(studentA, atDesk: deskIndex, adjacencyMap: adjacencyMap, keepApartRules: keepApartRules) else { continue }

                let adjacentDesks = (adjacencyMap[deskIndex] ?? []).shuffled()
                for adjDeskIndex in adjacentDesks {
                    guard desks[adjDeskIndex].assignedStudentIDs.isEmpty else { continue }
                    guard canPlaceStudent(studentB, atDesk: adjDeskIndex, adjacencyMap: adjacencyMap, keepApartRules: keepApartRules) else { continue }

                    desks[deskIndex].assignedStudentIDs.append(idA)
                    desks[adjDeskIndex].assignedStudentIDs.append(idB)
                    placedStudentIDs.insert(idA)
                    placedStudentIDs.insert(idB)
                    remainingStudents.removeAll { $0.id == idA || $0.id == idB }
                    break
                }

                if placedStudentIDs.contains(idA) { break }
            }
        }

        // STEP 2: Place remaining students
        shuffledDeskIndices = shuffledDeskIndices.shuffled()
        var attempts = 0
        let maxAttempts = 100

        while !remainingStudents.isEmpty && attempts < maxAttempts {
            attempts += 1
            var madeProgress = false

            for deskIndex in shuffledDeskIndices {
                guard !remainingStudents.isEmpty else { break }
                guard desks[deskIndex].assignedStudentIDs.isEmpty else { continue }

                for (studentIndex, student) in remainingStudents.enumerated() {
                    guard let studentID = student.id else { continue }

                    if canPlaceStudent(student, atDesk: deskIndex, adjacencyMap: adjacencyMap, keepApartRules: keepApartRules) {
                        desks[deskIndex].assignedStudentIDs.append(studentID)
                        placedStudentIDs.insert(studentID)
                        remainingStudents.remove(at: studentIndex)
                        madeProgress = true
                        break
                    }
                }
            }

            if !madeProgress && !remainingStudents.isEmpty {
                // Fallback: place remaining students regardless of constraints
                for deskIndex in shuffledDeskIndices {
                    guard !remainingStudents.isEmpty else { break }
                    guard desks[deskIndex].assignedStudentIDs.isEmpty else { continue }

                    if let student = remainingStudents.first, let studentID = student.id {
                        desks[deskIndex].assignedStudentIDs.append(studentID)
                        remainingStudents.removeFirst()
                    }
                }
                break
            }
        }

        saveDesks()
        hapticSuccess.notificationOccurred(.success)
        showToast(message: "Seating randomized")
    }

    private func buildDeskAdjacencyMap() -> [Int: Set<Int>] {
        var adjacencyMap: [Int: Set<Int>] = [:]
        let proximityThreshold: CGFloat = 150

        for i in desks.indices {
            adjacencyMap[i] = []
            for j in desks.indices where i != j {
                let distance = hypot(
                    desks[i].position.x - desks[j].position.x,
                    desks[i].position.y - desks[j].position.y
                )
                if distance <= proximityThreshold {
                    adjacencyMap[i]?.insert(j)
                }
            }
        }
        return adjacencyMap
    }

    private func canPlaceStudent(
        _ student: Student,
        atDesk deskIndex: Int,
        adjacencyMap: [Int: Set<Int>],
        keepApartRules: [SeatingRule]
    ) -> Bool {
        guard student.id != nil else { return true }

        let adjacentDeskIndices = adjacencyMap[deskIndex] ?? []

        var adjacentStudentIDs = Set<UUID>()
        for adjIndex in adjacentDeskIndices {
            for id in desks[adjIndex].assignedStudentIDs {
                adjacentStudentIDs.insert(id)
            }
        }

        for rule in keepApartRules {
            guard rule.involves(student: student) else { continue }

            if let otherStudent = rule.otherStudent(from: student),
               let otherID = otherStudent.id,
               adjacentStudentIDs.contains(otherID) {
                return false
            }
        }

        return true
    }

    private func showToast(message: String) {
        toastMessage = message
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showToast = false
            }
        }
    }

    private func autoSaveAttendance() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: attendanceDate)

        for (studentId, status) in attendanceStatus {
            if let student = students.first(where: { $0.id == studentId }) {
                _ = AttendanceRecord.createOrUpdate(
                    context: viewContext,
                    student: student,
                    classPeriod: classPeriod,
                    date: startOfDay,
                    status: status
                )
            }
        }

        do {
            try viewContext.save()
        } catch {
            // Silent save on disappear - user can resave if needed
            #if DEBUG
            print("Auto-save attendance failed: \(error)")
            #endif
        }
    }

    private func clearAllAssignments() {
        for i in desks.indices {
            desks[i].assignedStudentIDs.removeAll()
        }
        saveDesks()
    }

    private func saveDesks() {
        guard let classroom = activeClassroom else { return }

        do {
            let data = try JSONEncoder().encode(desks)
            classroom.deskPositions = data
            try viewContext.save()
        } catch {
            showToast(message: "Failed to save layout")
            #if DEBUG
            print("Save desks error: \(error)")
            #endif
        }
    }

    private func switchToLayout(_ layout: Classroom) {
        if let classrooms = classPeriod.classrooms as? Set<Classroom> {
            for classroom in classrooms {
                classroom.isActive = (classroom == layout)
            }
        }

        do {
            try viewContext.save()
            loadDesks()
        } catch {
            showToast(message: "Failed to switch layout")
            #if DEBUG
            print("Switch layout error: \(error)")
            #endif
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let classPeriod = ClassPeriod(context: context)
    classPeriod.id = UUID()
    classPeriod.name = "3rd Period Math"

    return NavigationStack {
        MainSeatingChartView(classPeriod: classPeriod)
            .environment(\.managedObjectContext, context)
            .environmentObject(AppStateManager())
    }
}
