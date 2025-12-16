//
//  AttendanceRecord+Extensions.swift
//  SeatingChart
//
//  Created by Claude
//

import Foundation
import CoreData
import SwiftUI

enum AttendanceStatus: String, CaseIterable {
    case present
    case absent
    case tardy

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .present:
            return .green
        case .absent:
            return .red
        case .tardy:
            return .yellow
        }
    }

    var icon: String {
        switch self {
        case .present:
            return "checkmark.circle.fill"
        case .absent:
            return "xmark.circle.fill"
        case .tardy:
            return "clock.fill"
        }
    }

    var next: AttendanceStatus {
        switch self {
        case .present:
            return .absent
        case .absent:
            return .tardy
        case .tardy:
            return .present
        }
    }
}

extension AttendanceRecord {
    var attendanceStatus: AttendanceStatus {
        get {
            AttendanceStatus(rawValue: status ?? "present") ?? .present
        }
        set {
            status = newValue.rawValue
        }
    }

    convenience init(context: NSManagedObjectContext, student: Student, classPeriod: ClassPeriod, date: Date, status: AttendanceStatus) {
        self.init(context: context)
        self.id = UUID()
        self.student = student
        self.classPeriod = classPeriod
        self.date = date
        self.attendanceStatus = status
    }

    static func createOrUpdate(context: NSManagedObjectContext, student: Student, classPeriod: ClassPeriod, date: Date, status: AttendanceStatus) -> AttendanceRecord {
        // Check if record already exists for this student, class, and date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let fetchRequest: NSFetchRequest<AttendanceRecord> = AttendanceRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "student == %@ AND classPeriod == %@ AND date >= %@ AND date < %@",
            student, classPeriod, startOfDay as NSDate, endOfDay as NSDate
        )

        if let existing = try? context.fetch(fetchRequest).first {
            existing.attendanceStatus = status
            return existing
        } else {
            return AttendanceRecord(context: context, student: student, classPeriod: classPeriod, date: date, status: status)
        }
    }
}
