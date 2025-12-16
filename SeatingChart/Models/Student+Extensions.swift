//
//  Student+Extensions.swift
//  SeatingChart
//
//  Created by Claude
//

import Foundation
import CoreData
import UIKit
import SwiftUI

extension Student {
    var classesArray: [ClassPeriod] {
        if let classPeriod = classPeriod {
            return [classPeriod]
        }
        return []
    }

    var seatAssignmentsArray: [SeatAssignment] {
        let set = seatAssignments as? Set<SeatAssignment> ?? []
        return set.sorted { ($0.classPeriod?.name ?? "") < ($1.classPeriod?.name ?? "") }
    }

    var attendanceRecordsArray: [AttendanceRecord] {
        let set = attendanceRecords as? Set<AttendanceRecord> ?? []
        return set.sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }
    }

    var photo: UIImage? {
        get {
            guard let data = photoData else { return nil }
            return UIImage(data: data)
        }
        set {
            photoData = newValue?.jpegData(compressionQuality: 0.7)
        }
    }

    convenience init(context: NSManagedObjectContext, name: String, photo: UIImage? = nil) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        if let photo = photo {
            self.photo = photo
        }
    }

    func attendanceStats(for classPeriod: ClassPeriod) -> (present: Int, absent: Int, tardy: Int) {
        let records = attendanceRecordsArray.filter { $0.classPeriod == classPeriod }
        var present = 0
        var absent = 0
        var tardy = 0

        for record in records {
            switch record.status {
            case "present":
                present += 1
            case "absent":
                absent += 1
            case "tardy":
                tardy += 1
            default:
                break
            }
        }

        return (present, absent, tardy)
    }

    func totalAttendanceStats() -> (present: Int, absent: Int, tardy: Int) {
        var present = 0
        var absent = 0
        var tardy = 0

        for record in attendanceRecordsArray {
            switch record.status {
            case "present":
                present += 1
            case "absent":
                absent += 1
            case "tardy":
                tardy += 1
            default:
                break
            }
        }

        return (present, absent, tardy)
    }
}
