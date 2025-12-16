//
//  AttendanceExportView.swift
//  SeatingChart
//
//  Created on 2025-11-29.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct AttendanceExportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var classPeriod: ClassPeriod

    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var includeStudentIDs = true
    @State private var showingShareSheet = false
    @State private var csvURL: URL?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Date Range")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }

                Section(header: Text("Export Options")) {
                    Toggle("Include Student IDs", isOn: $includeStudentIDs)
                }

                Section {
                    Button(action: generateAndExportCSV) {
                        HStack {
                            Spacer()
                            Label("Export as CSV", systemImage: "square.and.arrow.up")
                            Spacer()
                        }
                    }
                }

                Section(footer: Text("Export attendance data for the selected date range as a CSV file that can be opened in spreadsheet applications.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Export Attendance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = csvURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func generateAndExportCSV() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: startDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate))!

        // Fetch attendance records
        let request: NSFetchRequest<AttendanceRecord> = AttendanceRecord.fetchRequest()
        request.predicate = NSPredicate(
            format: "classPeriod == %@ AND date >= %@ AND date < %@",
            classPeriod, startOfDay as NSDate, endOfDay as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \AttendanceRecord.date, ascending: true),
            NSSortDescriptor(keyPath: \AttendanceRecord.student?.lastName, ascending: true)
        ]

        guard let records = try? viewContext.fetch(request) else {
            print("Failed to fetch attendance records")
            return
        }

        // Generate CSV content
        var csvText = generateCSVHeader()
        csvText += "\n"

        for record in records {
            csvText += generateCSVRow(for: record)
            csvText += "\n"
        }

        // Save to temporary file
        let fileName = "attendance_\(classPeriod.name ?? "class")_\(Date().timeIntervalSince1970).csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csvText.write(to: path, atomically: true, encoding: .utf8)
            csvURL = path
            showingShareSheet = true
        } catch {
            print("Error saving CSV: \(error.localizedDescription)")
        }
    }

    private func generateCSVHeader() -> String {
        var headers = ["Date", "Last Name", "First Name"]

        if includeStudentIDs {
            headers.append("Student ID")
        }

        headers.append("Status")

        return headers.joined(separator: ",")
    }

    private func generateCSVRow(for record: AttendanceRecord) -> String {
        var fields: [String] = []

        // Date
        if let date = record.date {
            fields.append(formatCSVField(date.formatted(date: .abbreviated, time: .omitted)))
        } else {
            fields.append("")
        }

        // Student name
        if let student = record.student {
            fields.append(formatCSVField(student.lastName ?? ""))
            fields.append(formatCSVField(student.firstName ?? ""))

            if includeStudentIDs {
                fields.append(formatCSVField(student.studentID ?? ""))
            }
        } else {
            fields.append("")
            fields.append("")
            if includeStudentIDs {
                fields.append("")
            }
        }

        // Status
        fields.append(formatCSVField(record.status ?? ""))

        return fields.joined(separator: ",")
    }

    private func formatCSVField(_ field: String) -> String {
        // Escape quotes and wrap in quotes if contains comma or quote
        if field.contains(",") || field.contains("\"") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let classPeriod = ClassPeriod(context: context)
    classPeriod.id = UUID()
    classPeriod.name = "Period 1"

    return AttendanceExportView(classPeriod: classPeriod)
        .environment(\.managedObjectContext, context)
}
