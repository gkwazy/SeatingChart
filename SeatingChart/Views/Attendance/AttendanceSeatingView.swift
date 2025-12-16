//
//  AttendanceSeatingView.swift
//  SeatingChart
//
//  Primary daily attendance view showing classroom layout
//

import SwiftUI
import CoreData

struct AttendanceSeatingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var classPeriod: ClassPeriod
    @EnvironmentObject var appStateManager: AppStateManager

    @State private var attendanceDate = Date()
    @State private var attendanceStatus: [UUID: AttendanceStatus] = [:]
    @State private var showPhotos = true
    @State private var desks: [Desk] = []
    @State private var showingEditLayout = false
    @State private var showingSaveConfirmation = false

    // Room settings
    @State private var roomSize = CGSize(width: 1000, height: 800)

    var activeClassroom: Classroom? {
        (classPeriod.classrooms as? Set<Classroom>)?.first(where: { $0.isActive }) ??
        (classPeriod.classrooms as? Set<Classroom>)?.first
    }

    var students: [Student] {
        let studentSet = classPeriod.students as? Set<Student> ?? []
        return studentSet.sorted { ($0.lastName ?? "") < ($1.lastName ?? "") }
    }

    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if let classroom = activeClassroom {
                // Main canvas with zoom/pan
                ZoomableCanvas {
                    ZStack {
                        // Room walls
                        RoomWallsView(size: roomSize)

                        // Desks with attendance status
                        ForEach(desks) { desk in
                            AttendanceDeskView(
                                desk: desk,
                                student: studentForDesk(desk),
                                status: statusForDesk(desk),
                                showPhoto: showPhotos,
                                privacyMode: appStateManager.privacyModeEnabled
                            )
                            .position(desk.position)
                            .onTapGesture {
                                cycleAttendanceStatus(for: desk)
                            }
                        }
                    }
                    .frame(width: roomSize.width, height: roomSize.height)
                }
            } else {
                // No layout created yet
                VStack(spacing: 16) {
                    Image(systemName: "square.grid.3x3.slash")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)

                    Text("No Layout Created")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Create a classroom layout to take attendance")
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
        }
        .navigationTitle("Attendance - \(attendanceDate.formatted(date: .abbreviated, time: .omitted))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                DatePicker("", selection: $attendanceDate, displayedComponents: .date)
                    .labelsHidden()
                    .onChange(of: attendanceDate) { _, _ in
                        loadExistingAttendance()
                    }
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Toggle(isOn: $showPhotos) {
                    Image(systemName: showPhotos ? "photo.fill" : "photo")
                }
                .toggleStyle(.button)

                Menu {
                    Button(action: markAllPresent) {
                        Label("Mark All Present", systemImage: "checkmark.circle.fill")
                    }

                    Button(action: saveAttendance) {
                        Label("Save Attendance", systemImage: "square.and.arrow.down")
                    }
                    .disabled(attendanceStatus.isEmpty)

                    Divider()

                    if activeClassroom != nil {
                        Button(action: { showingEditLayout = true }) {
                            Label("Edit Layout", systemImage: "pencil")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditLayout) {
            if let classroom = activeClassroom {
                NavigationStack {
                    EnhancedLayoutEditorView(classroom: classroom)
                }
            }
        }
        .alert("Attendance Saved", isPresented: $showingSaveConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Attendance has been recorded for \(attendanceDate.formatted(date: .abbreviated, time: .omitted))")
        }
        .onAppear {
            loadDesks()
            loadExistingAttendance()
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
        // Find student assigned to this desk
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

    private func cycleAttendanceStatus(for desk: Desk) {
        guard let student = studentForDesk(desk),
              let studentID = student.id else {
            return
        }

        let currentStatus = attendanceStatus[studentID] ?? .present
        attendanceStatus[studentID] = currentStatus.next
    }

    private func loadExistingAttendance() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: attendanceDate)
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
        }
    }

    private func markAllPresent() {
        for student in students {
            if let id = student.id {
                attendanceStatus[id] = .present
            }
        }
    }

    private func saveAttendance() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: attendanceDate)

        // Create or update records for each student with a status
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
            showingSaveConfirmation = true
        } catch {
            print("Error saving attendance: \(error.localizedDescription)")
        }
    }
}

// MARK: - Attendance Desk View

struct AttendanceDeskView: View {
    let desk: Desk
    let student: Student?
    let status: AttendanceStatus
    let showPhoto: Bool
    let privacyMode: Bool

    var body: some View {
        ZStack {
            // Desk background with status color
            if student != nil {
                RoundedRectangle(cornerRadius: 8)
                    .fill(status.color.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(status.color, lineWidth: 3)
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

                    // Status label
                    Text(status.displayName)
                        .font(.system(size: 10))
                        .fontWeight(.semibold)
                        .foregroundColor(status.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white)
                        .cornerRadius(4)
                }
                .padding(8)
            } else {
                Text("Empty")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: desk.size.width, height: desk.size.height)
        .rotationEffect(desk.rotation)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let classPeriod = ClassPeriod(context: context)
    classPeriod.id = UUID()
    classPeriod.name = "Period 1"

    return NavigationStack {
        AttendanceSeatingView(classPeriod: classPeriod)
            .environment(\.managedObjectContext, context)
            .environmentObject(AppStateManager())
    }
}
