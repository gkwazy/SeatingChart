//
//  MainSeatingChartView.swift
//  SeatingChart
//
//  Primary view shown when opening a class
//  Shows seating chart with action buttons at top
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
    @State private var showingDatePicker = false

    // Navigation
    @State private var showingRoster = false
    @State private var showingEditLayout = false
    @State private var showingSaveConfirmation = false
    @State private var showingRandomConfirmation = false
    @State private var showingLayoutPicker = false

    // Student assignment
    @State private var selectedDesk: Desk?
    @State private var showingStudentPicker = false

    // Room settings - adaptive to screen size
    @State private var roomSize = CGSize(width: 1000, height: 800)

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

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top action buttons
                    actionButtonsBar

                    // Main seating chart
                    if let _ = activeClassroom {
                        AdaptiveSeatingCanvas(
                            desks: desks,
                            students: students,
                            isTakingAttendance: isTakingAttendance,
                            attendanceStatus: attendanceStatus,
                            showPhotos: showPhotos,
                            privacyMode: appStateManager.privacyModeEnabled,
                            onDeskTap: handleDeskTap,
                            availableSize: CGSize(
                                width: geometry.size.width,
                                height: geometry.size.height - 70 // Account for action bar
                            )
                        )
                        .clipped() // Prevent desks from drawing over buttons
                    } else {
                        // No layout created yet
                        noLayoutView
                    }
                }
            }
        }
        .navigationTitle(classPeriod.name ?? "Class")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Toggle(isOn: $showPhotos) {
                    Image(systemName: showPhotos ? "photo.fill" : "photo")
                }
                .toggleStyle(.button)
            }
        }
        .sheet(isPresented: $showingRoster) {
            NavigationStack {
                StudentRosterView(classPeriod: classPeriod)
            }
        }
        .sheet(isPresented: $showingEditLayout, onDismiss: {
            // Reload desks after editing layout
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
        .sheet(isPresented: $showingStudentPicker) {
            if let desk = selectedDesk {
                StudentAssignmentSheet(
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
        }
        .alert("Start Taking Attendance?", isPresented: $showingDatePicker) {
            Button("Cancel", role: .cancel) { }
            Button("Start") {
                startTakingAttendance()
            }
        } message: {
            Text("Mark attendance for \(attendanceDate.formatted(date: .abbreviated, time: .omitted))")
        }
        .alert("Attendance Saved", isPresented: $showingSaveConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Attendance has been recorded for \(attendanceDate.formatted(date: .abbreviated, time: .omitted))")
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
        .onAppear {
            loadDesks()
            loadTodaysAttendance()
        }
    }

    // MARK: - Action Buttons Bar

    private var actionButtonsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if !isTakingAttendance {
                    ActionButton(
                        title: "Attendance",
                        icon: "checkmark.circle",
                        color: .green,
                        action: { showingDatePicker = true }
                    )

                    ActionButton(
                        title: "Random",
                        icon: "shuffle",
                        color: .blue,
                        action: { showingRandomConfirmation = true }
                    )
                } else {
                    ActionButton(
                        title: "Save",
                        icon: "square.and.arrow.down",
                        color: .blue,
                        action: saveAttendance
                    )

                    Button(action: { isTakingAttendance = false }) {
                        VStack(spacing: 4) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 20))
                            Text("Cancel")
                                .font(.caption2)
                        }
                        .foregroundColor(.white)
                        .frame(width: 70, height: 50)
                        .background(Color.red)
                        .cornerRadius(8)
                    }
                }

                ActionButton(
                    title: "Roster",
                    icon: "person.3",
                    color: .purple,
                    action: { showingRoster = true }
                )

                ActionButton(
                    title: "Layout",
                    icon: "square.grid.2x2",
                    color: .gray,
                    action: { showingLayoutPicker = true }
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }

    private var noLayoutView: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.3x3.slash")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Layout Created")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create a classroom layout to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(action: { showingEditLayout = true }) {
                Label("Create Layout", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
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
            // Cycle attendance status
            guard let student = studentForDesk(desk),
                  let studentID = student.id else {
                return
            }

            let currentStatus = attendanceStatus[studentID] ?? .present
            attendanceStatus[studentID] = currentStatus.next
        } else {
            // Student assignment mode
            selectedDesk = desk
            showingStudentPicker = true
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
            // Load today's attendance status (but don't enter attendance-taking mode)
            attendanceStatus.removeAll()
            for record in records {
                if let studentId = record.student?.id {
                    attendanceStatus[studentId] = record.attendanceStatus
                }
            }
        }
    }

    private func startTakingAttendance() {
        isTakingAttendance = true

        // Mark students as present only if they don't already have a status
        for student in students {
            if let id = student.id, attendanceStatus[id] == nil {
                attendanceStatus[id] = .present
            }
        }
    }

    private func saveAttendance() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: attendanceDate)

        // Create or update records for each student
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
            isTakingAttendance = false  // Exit attendance mode after saving
            showingSaveConfirmation = true
        } catch {
            print("Error saving attendance: \(error.localizedDescription)")
        }
    }

    // MARK: - Student Assignment

    private func assignStudent(_ student: Student, to desk: Desk) {
        guard let deskIndex = desks.firstIndex(where: { $0.id == desk.id }),
              let studentID = student.id else { return }

        // Remove student from any other desk first
        for i in desks.indices {
            desks[i].assignedStudentIDs.removeAll { $0 == studentID }
        }

        // Assign to selected desk
        desks[deskIndex].assignedStudentIDs.append(studentID)
        saveDesks()
    }

    private func unassignStudent(from desk: Desk) {
        guard let deskIndex = desks.firstIndex(where: { $0.id == desk.id }) else { return }
        desks[deskIndex].assignedStudentIDs.removeAll()
        saveDesks()
    }

    private func randomizeSeating() {
        // Clear all assignments
        for i in desks.indices {
            desks[i].assignedStudentIDs.removeAll()
        }

        // Sort desk indices by position: bottom first (highest Y), then left to right (lowest X)
        let sortedIndices = desks.indices.sorted { i1, i2 in
            if desks[i1].position.y != desks[i2].position.y {
                return desks[i1].position.y > desks[i2].position.y // Higher Y = bottom = first
            }
            return desks[i1].position.x < desks[i2].position.x // Lower X = left = first
        }

        // Shuffle students and assign to desks (front/bottom rows first)
        var shuffledStudents = students.shuffled()
        for deskIndex in sortedIndices {
            guard !shuffledStudents.isEmpty else { break }
            let student = shuffledStudents.removeFirst()
            if let studentID = student.id {
                desks[deskIndex].assignedStudentIDs.append(studentID)
            }
        }
        saveDesks()
    }

    private func clearAllAssignments() {
        for i in desks.indices {
            desks[i].assignedStudentIDs.removeAll()
        }
        saveDesks()
    }

    private func saveDesks() {
        guard let classroom = activeClassroom,
              let data = try? JSONEncoder().encode(desks) else { return }
        classroom.deskPositions = data
        try? viewContext.save()
    }

    private func switchToLayout(_ layout: Classroom) {
        // Deactivate all other layouts for this class
        if let classrooms = classPeriod.classrooms as? Set<Classroom> {
            for classroom in classrooms {
                classroom.isActive = (classroom == layout)
            }
        }

        try? viewContext.save()

        // Reload desks from the new layout
        loadDesks()
    }
}

// MARK: - Layout Picker Sheet

struct LayoutPickerSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var classPeriod: ClassPeriod
    let currentLayout: Classroom?
    let onSelectLayout: (Classroom) -> Void
    let onEditLayout: () -> Void

    @State private var showingNewLayoutSheet = false
    @State private var newLayoutName = ""

    var layouts: [Classroom] {
        let classrooms = classPeriod.classrooms as? Set<Classroom> ?? []
        return classrooms.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(layouts, id: \.id) { layout in
                        Button {
                            onSelectLayout(layout)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(layout.name ?? "Unnamed Layout")
                                        .foregroundColor(.primary)

                                    if let deskData = layout.deskPositions,
                                       let deskCount = try? JSONDecoder().decode([Desk].self, from: deskData).count {
                                        Text("\(deskCount) desks")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                if layout == currentLayout {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteLayouts)
                } header: {
                    Text("Saved Layouts")
                }

                Section {
                    Button {
                        showingNewLayoutSheet = true
                    } label: {
                        Label("Create New Layout", systemImage: "plus.circle")
                    }

                    if currentLayout != nil {
                        Button {
                            dismiss()
                            onEditLayout()
                        } label: {
                            Label("Edit Current Layout", systemImage: "pencil")
                        }
                    }
                }
            }
            .navigationTitle("Layouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("New Layout", isPresented: $showingNewLayoutSheet) {
                TextField("Layout Name", text: $newLayoutName)
                Button("Cancel", role: .cancel) {
                    newLayoutName = ""
                }
                Button("Create") {
                    createNewLayout()
                }
            } message: {
                Text("Enter a name for the new layout")
            }
        }
    }

    private func createNewLayout() {
        let newLayout = Classroom(context: viewContext)
        newLayout.id = UUID()
        newLayout.name = newLayoutName.isEmpty ? "New Layout" : newLayoutName
        newLayout.rows = 5
        newLayout.columns = 6
        newLayout.isActive = layouts.isEmpty // Make active if first layout

        // Add to the classPeriod's classrooms relationship
        let mutableClassrooms = classPeriod.mutableSetValue(forKey: "classrooms")
        mutableClassrooms.add(newLayout)

        try? viewContext.save()
        newLayoutName = ""

        // If this is the first layout, select it and open editor
        if layouts.count == 1 {
            onSelectLayout(newLayout)
            dismiss()
        }
    }

    private func deleteLayouts(offsets: IndexSet) {
        for index in offsets {
            let layout = layouts[index]
            // Don't delete the active layout
            if layout != currentLayout {
                viewContext.delete(layout)
            }
        }
        try? viewContext.save()
    }
}

// MARK: - Student Picker Sheet

struct StudentAssignmentSheet: View {
    let desk: Desk
    let students: [Student]
    let assignedStudent: Student?
    let onAssign: (Student) -> Void
    let onUnassign: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if assignedStudent != nil {
                    Section {
                        Button(role: .destructive) {
                            onUnassign()
                            dismiss()
                        } label: {
                            Label("Remove from Desk", systemImage: "person.badge.minus")
                        }
                    }
                }

                Section(students.isEmpty ? "No Unassigned Students" : "Assign Student") {
                    ForEach(students) { student in
                        Button {
                            onAssign(student)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                if let photoData = student.photoData,
                                   let uiImage = UIImage(data: photoData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.gray)
                                }

                                VStack(alignment: .leading) {
                                    Text("\(student.firstName ?? "") \(student.lastName ?? "")")
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(assignedStudent != nil ? "Change Assignment" : "Assign Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Desk Display View

struct DeskDisplayView: View {
    let desk: Desk
    let student: Student?
    let status: AttendanceStatus?
    let showPhoto: Bool
    let privacyMode: Bool

    var backgroundColor: Color {
        if let status = status {
            return status.color.opacity(0.3)
        }
        return Color.gray.opacity(0.15)
    }

    var borderColor: Color {
        if let status = status {
            return status.color
        }
        return Color.gray.opacity(0.4)
    }

    var body: some View {
        ZStack {
            // Desk background
            if student != nil {
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(borderColor, lineWidth: status != nil ? 3 : 2)
                    )
            } else {
                // Empty desk
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    )
            }

            // Front indicator bar (at bottom of desk - front of classroom)
            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue.opacity(0.6))
                    .frame(width: desk.size.width * 0.6, height: 4)
                    .padding(.bottom, 4)
            }

            // Student info
            if let student = student {
                VStack(spacing: 4) {
                    // Photo
                    if showPhoto {
                        if let photoData = student.photoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: privacyMode ? (PhotoManager.shared.blurImage(uiImage) ?? uiImage) : uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.gray)
                        }
                    }

                    // Name
                    Text(student.name ?? "Unknown")
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    // Status label (only when taking attendance)
                    if let status = status {
                        Text(status.displayName)
                            .font(.system(size: 10))
                            .fontWeight(.semibold)
                            .foregroundColor(status.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white)
                            .cornerRadius(4)
                    }
                }
                .padding(8)
            } else {
                // Empty desk - show tap to assign hint
                VStack(spacing: 4) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundColor(.gray.opacity(0.5))
                    Text("Tap to assign")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(width: desk.size.width, height: desk.size.height)
        .contentShape(Rectangle()) // Ensures entire desk area is tappable
        .rotationEffect(desk.rotation)
    }
}

// MARK: - Adaptive Seating Canvas

struct AdaptiveSeatingCanvas: View {
    let desks: [Desk]
    let students: [Student]
    let isTakingAttendance: Bool
    let attendanceStatus: [UUID: AttendanceStatus]
    let showPhotos: Bool
    let privacyMode: Bool
    let onDeskTap: (Desk) -> Void
    let availableSize: CGSize

    // Padding between desks (multiplier for spacing)
    private let deskPadding: CGFloat = 1.15

    // Zoom gesture state
    @State private var currentZoom: CGFloat = 1.0
    @State private var lastZoom: CGFloat = 1.0

    // Pan gesture state
    @State private var currentOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // Zoom limits
    private let maxZoom: CGFloat = 3.0

    // Calculate minimum zoom to prevent desks from becoming too small
    private var minZoom: CGFloat {
        // The minimum zoom ensures desks stay at least 50pt in their smallest dimension
        // Since initialScale already fits content to screen, we just need to prevent
        // zooming out too far from that baseline
        return 0.7
    }

    // Calculate the bounding box of all desks with spread positioning
    private var desksBounds: CGRect {
        guard !desks.isEmpty else {
            return CGRect(x: 0, y: 0, width: 400, height: 300)
        }

        // Need to calculate center first for spread positions
        let sumX = desks.reduce(0) { $0 + $1.position.x }
        let sumY = desks.reduce(0) { $0 + $1.position.y }
        let center = CGPoint(x: sumX / CGFloat(desks.count), y: sumY / CGFloat(desks.count))

        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude

        for desk in desks {
            // Calculate spread position
            let spreadX = center.x + (desk.position.x - center.x) * deskPadding
            let spreadY = center.y + (desk.position.y - center.y) * deskPadding

            minX = min(minX, spreadX - desk.size.width / 2)
            minY = min(minY, spreadY - desk.size.height / 2)
            maxX = max(maxX, spreadX + desk.size.width / 2)
            maxY = max(maxY, spreadY + desk.size.height / 2)
        }

        // Add edge padding
        let edgePadding: CGFloat = 60
        return CGRect(
            x: minX - edgePadding,
            y: minY - edgePadding,
            width: maxX - minX + edgePadding * 2,
            height: maxY - minY + edgePadding * 2
        )
    }

    // Calculate initial scale to fit content
    private var initialScale: CGFloat {
        let bounds = desksBounds
        guard bounds.width > 0 && bounds.height > 0 else { return 1.0 }

        let scaleX = availableSize.width / bounds.width
        let scaleY = availableSize.height / bounds.height
        let scale = min(scaleX, scaleY) * 0.9 // 90% to add some margin
        return max(min(scale, 1.5), 0.3)
    }

    // Combined scale (initial + user zoom)
    private var totalScale: CGFloat {
        initialScale * currentZoom
    }

    // Center point of all desks
    private var desksCenter: CGPoint {
        guard !desks.isEmpty else { return .zero }
        let sumX = desks.reduce(0) { $0 + $1.position.x }
        let sumY = desks.reduce(0) { $0 + $1.position.y }
        return CGPoint(x: sumX / CGFloat(desks.count), y: sumY / CGFloat(desks.count))
    }

    // Calculate spread-out position for a desk (adds spacing between desks)
    private func spreadPosition(for desk: Desk) -> CGPoint {
        let center = desksCenter
        // Spread positions outward from center
        let spreadX = center.x + (desk.position.x - center.x) * deskPadding
        let spreadY = center.y + (desk.position.y - center.y) * deskPadding
        return CGPoint(x: spreadX, y: spreadY)
    }

    // Offset to center content
    private var centerOffset: CGSize {
        let bounds = desksBounds
        return CGSize(
            width: availableSize.width / 2 - bounds.midX * totalScale,
            height: availableSize.height / 2 - bounds.midY * totalScale
        )
    }

    private func studentForDesk(_ desk: Desk) -> Student? {
        guard let studentID = desk.assignedStudentIDs.first else { return nil }
        return students.first(where: { $0.id == studentID })
    }

    private func statusForDesk(_ desk: Desk) -> AttendanceStatus? {
        guard let student = studentForDesk(desk),
              let studentID = student.id else {
            return nil
        }
        // Return status if we have attendance data (either taking attendance or viewing saved data)
        return attendanceStatus[studentID]
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background for gestures
                Color(.systemGroupedBackground)

                // Desks container
                ZStack {
                    ForEach(desks) { desk in
                        let spreadPos = spreadPosition(for: desk)
                        DeskDisplayView(
                            desk: desk,
                            student: studentForDesk(desk),
                            status: statusForDesk(desk),
                            showPhoto: showPhotos,
                            privacyMode: privacyMode
                        )
                        .position(
                            x: spreadPos.x * totalScale + centerOffset.width + currentOffset.width,
                            y: spreadPos.y * totalScale + centerOffset.height + currentOffset.height
                        )
                        .scaleEffect(totalScale)
                        .onTapGesture {
                            onDeskTap(desk)
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let delta = value / lastZoom
                        lastZoom = value
                        let newZoom = currentZoom * delta
                        currentZoom = min(max(newZoom, minZoom), maxZoom)
                    }
                    .onEnded { _ in
                        lastZoom = 1.0
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        currentOffset = CGSize(
                            width: lastOffset.width + value.translation.width,
                            height: lastOffset.height + value.translation.height
                        )
                    }
                    .onEnded { _ in
                        lastOffset = currentOffset
                    }
            )
            .onTapGesture(count: 2) {
                // Double-tap to reset zoom
                withAnimation(.spring(response: 0.3)) {
                    currentZoom = 1.0
                    lastZoom = 1.0
                    currentOffset = .zero
                    lastOffset = .zero
                }
            }
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(.white)
            .frame(width: 70, height: 50)
            .background(color)
            .cornerRadius(8)
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
