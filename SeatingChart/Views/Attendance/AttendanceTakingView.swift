//
//  AttendanceTakingView.swift
//  SeatingChart
//
//  Created on 2025-11-29.
//

import SwiftUI
import CoreData

struct AttendanceTakingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var classPeriod: ClassPeriod

    @State private var attendanceDate = Date()
    @State private var attendanceStatus: [UUID: AttendanceStatus] = [:]
    @State private var showingSaveConfirmation = false

    enum AttendanceStatus: String {
        case present = "Present"
        case absent = "Absent"
        case tardy = "Tardy"
        case excused = "Excused"

        var color: Color {
            switch self {
            case .present: return .green
            case .absent: return .red
            case .tardy: return .orange
            case .excused: return .blue
            }
        }

        var icon: String {
            switch self {
            case .present: return "checkmark.circle.fill"
            case .absent: return "xmark.circle.fill"
            case .tardy: return "clock.fill"
            case .excused: return "hand.raised.fill"
            }
        }
    }

    var students: [Student] {
        let studentSet = classPeriod.students as? Set<Student> ?? []
        return studentSet.sorted { ($0.lastName ?? "") < ($1.lastName ?? "") }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Date picker
            VStack(spacing: 8) {
                DatePicker("Date", selection: $attendanceDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding(.horizontal)

                Divider()
            }
            .background(Color(.systemBackground))

            // Student list
            List {
                ForEach(students) { student in
                    AttendanceRow(
                        student: student,
                        status: attendanceStatus[student.id ?? UUID()],
                        onStatusChange: { status in
                            attendanceStatus[student.id ?? UUID()] = status
                        }
                    )
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            withAnimation {
                                attendanceStatus[student.id ?? UUID()] = .present
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            Label("Present", systemImage: "checkmark.circle.fill")
                        }
                        .tint(.green)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            withAnimation {
                                attendanceStatus[student.id ?? UUID()] = .absent
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            Label("Absent", systemImage: "xmark.circle.fill")
                        }
                        .tint(.red)

                        Button {
                            withAnimation {
                                attendanceStatus[student.id ?? UUID()] = .tardy
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            Label("Tardy", systemImage: "clock.fill")
                        }
                        .tint(.orange)
                    }
                }
            }

            // Quick actions
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button(action: markAllPresent) {
                        Text("All Present")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.green)
                            .cornerRadius(8)
                    }

                    Button(action: clearAll) {
                        Text("Clear All")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.gray)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)

                Button(action: saveAttendance) {
                    Text("Save Attendance")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(attendanceStatus.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(attendanceStatus.isEmpty)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(Color(.systemBackground))
        }
        .navigationTitle("Take Attendance")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadExistingAttendance()
        }
        .alert("Attendance Saved", isPresented: $showingSaveConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Attendance has been recorded for \(attendanceDate.formatted(date: .abbreviated, time: .omitted))")
        }
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
                if let studentId = record.student?.id, let status = record.status {
                    attendanceStatus[studentId] = AttendanceStatus(rawValue: status)
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

    private func clearAll() {
        attendanceStatus.removeAll()
    }

    private func saveAttendance() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: attendanceDate)

        // Delete existing records for this date
        let deleteRequest: NSFetchRequest<AttendanceRecord> = AttendanceRecord.fetchRequest()
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        deleteRequest.predicate = NSPredicate(
            format: "classPeriod == %@ AND date >= %@ AND date < %@",
            classPeriod, startOfDay as NSDate, endOfDay as NSDate
        )

        if let existingRecords = try? viewContext.fetch(deleteRequest) {
            existingRecords.forEach(viewContext.delete)
        }

        // Create new records
        for (studentId, status) in attendanceStatus {
            if let student = students.first(where: { $0.id == studentId }) {
                let record = AttendanceRecord(context: viewContext)
                record.id = UUID()
                record.date = startOfDay
                record.status = status.rawValue
                record.student = student
                record.classPeriod = classPeriod
            }
        }

        do {
            try viewContext.save()
            showingSaveConfirmation = true
        } catch {
            #if DEBUG
            print("Error saving attendance: \(error.localizedDescription)")
            #endif
        }
    }
}

struct AttendanceRow: View {
    let student: Student
    let status: AttendanceTakingView.AttendanceStatus?
    let onStatusChange: (AttendanceTakingView.AttendanceStatus) -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                if let photoData = student.photoData, let uiImage = UIImage(data: photoData) {
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

                Text("\(student.firstName ?? "") \(student.lastName ?? "")")
                    .font(.headline)

                Spacer()

                if let status = status {
                    Image(systemName: status.icon)
                        .foregroundColor(status.color)
                }
            }

            HStack(spacing: 8) {
                ForEach([
                    AttendanceTakingView.AttendanceStatus.present,
                    .absent,
                    .tardy,
                    .excused
                ], id: \.self) { statusOption in
                    Button(action: {
                        onStatusChange(statusOption)
                    }) {
                        Text(statusOption.rawValue)
                            .font(.caption)
                            .foregroundColor(status == statusOption ? .white : statusOption.color)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(status == statusOption ? statusOption.color : statusOption.color.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let classPeriod = ClassPeriod(context: context)
    classPeriod.id = UUID()
    classPeriod.name = "Period 1"

    let student = Student(context: context)
    student.id = UUID()
    student.firstName = "John"
    student.lastName = "Doe"
    student.classPeriod = classPeriod

    return NavigationStack {
        AttendanceTakingView(classPeriod: classPeriod)
            .environment(\.managedObjectContext, context)
    }
}
