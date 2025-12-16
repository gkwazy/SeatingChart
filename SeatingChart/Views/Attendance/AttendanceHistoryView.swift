//
//  AttendanceHistoryView.swift
//  SeatingChart
//
//  Created on 2025-11-29.
//

import SwiftUI
import CoreData

struct AttendanceHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var classPeriod: ClassPeriod

    @State private var selectedDate: Date?
    @State private var showingExportView = false

    @FetchRequest private var attendanceRecords: FetchedResults<AttendanceRecord>

    init(classPeriod: ClassPeriod) {
        self.classPeriod = classPeriod

        _attendanceRecords = FetchRequest<AttendanceRecord>(
            sortDescriptors: [NSSortDescriptor(keyPath: \AttendanceRecord.date, ascending: false)],
            predicate: NSPredicate(format: "classPeriod == %@", classPeriod),
            animation: .default
        )
    }

    var groupedRecords: [Date: [AttendanceRecord]] {
        Dictionary(grouping: attendanceRecords) { record in
            Calendar.current.startOfDay(for: record.date ?? Date())
        }
    }

    var sortedDates: [Date] {
        groupedRecords.keys.sorted(by: >)
    }

    var body: some View {
        List {
            if sortedDates.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)

                    Text("No Attendance Records")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Take attendance to see history here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ForEach(sortedDates, id: \.self) { date in
                    Section(header: DateHeaderView(date: date)) {
                        if let records = groupedRecords[date] {
                            AttendanceSummaryRow(records: records)
                                .onTapGesture {
                                    selectedDate = date
                                }
                        }
                    }
                }
            }
        }
        .navigationTitle("Attendance History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingExportView = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(sortedDates.isEmpty)
            }
        }
        .sheet(item: $selectedDate) { date in
            AttendanceDetailSheet(
                classPeriod: classPeriod,
                date: date,
                records: groupedRecords[date] ?? []
            )
        }
        .sheet(isPresented: $showingExportView) {
            AttendanceExportView(classPeriod: classPeriod)
        }
    }
}

struct DateHeaderView: View {
    let date: Date

    var body: some View {
        Text(date.formatted(date: .complete, time: .omitted))
            .font(.subheadline)
            .fontWeight(.semibold)
    }
}

struct AttendanceSummaryRow: View {
    let records: [AttendanceRecord]

    var summary: [String: Int] {
        var counts: [String: Int] = [
            "Present": 0,
            "Absent": 0,
            "Tardy": 0,
            "Excused": 0
        ]

        for record in records {
            if let status = record.status {
                counts[status, default: 0] += 1
            }
        }

        return counts
    }

    var body: some View {
        HStack(spacing: 16) {
            StatBadge(label: "Present", count: summary["Present"] ?? 0, color: .green)
            StatBadge(label: "Absent", count: summary["Absent"] ?? 0, color: .red)
            StatBadge(label: "Tardy", count: summary["Tardy"] ?? 0, color: .orange)
            StatBadge(label: "Excused", count: summary["Excused"] ?? 0, color: .blue)
        }
        .padding(.vertical, 8)
    }
}

struct StatBadge: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.headline)
                .foregroundColor(color)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AttendanceDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let classPeriod: ClassPeriod
    let date: Date
    let records: [AttendanceRecord]

    var groupedByStatus: [String: [AttendanceRecord]] {
        Dictionary(grouping: records) { $0.status ?? "Unknown" }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(["Present", "Absent", "Tardy", "Excused"], id: \.self) { status in
                    if let statusRecords = groupedByStatus[status], !statusRecords.isEmpty {
                        Section(header: Text(status)) {
                            ForEach(statusRecords.sorted(by: {
                                ($0.student?.lastName ?? "") < ($1.student?.lastName ?? "")
                            })) { record in
                                if let student = record.student {
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
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(date.formatted(date: .abbreviated, time: .omitted))
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

extension Date: Identifiable {
    public var id: TimeInterval {
        self.timeIntervalSince1970
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let classPeriod = ClassPeriod(context: context)
    classPeriod.id = UUID()
    classPeriod.name = "Period 1"

    return NavigationStack {
        AttendanceHistoryView(classPeriod: classPeriod)
            .environment(\.managedObjectContext, context)
    }
}
