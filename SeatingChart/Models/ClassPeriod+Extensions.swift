//
//  ClassPeriod+Extensions.swift
//  SeatingChart
//
//  Created by Claude
//

import Foundation
import CoreData

extension ClassPeriod {
    var studentsArray: [Student] {
        let set = students as? Set<Student> ?? []
        return set.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    var seatAssignmentsArray: [SeatAssignment] {
        let set = seatAssignments as? Set<SeatAssignment> ?? []
        return set.sorted { ($0.deskY, $0.deskX) < ($1.deskY, $1.deskX) }
    }

    var attendanceRecordsArray: [AttendanceRecord] {
        let set = attendanceRecords as? Set<AttendanceRecord> ?? []
        return set.sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }
    }

    convenience init(context: NSManagedObjectContext, name: String, classroom: Classroom?) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.classroom = classroom
    }

    func seatAssignment(for student: Student) -> SeatAssignment? {
        seatAssignmentsArray.first { $0.student == student }
    }

    func student(at x: Int16, y: Int16) -> Student? {
        seatAssignmentsArray.first { $0.deskX == x && $0.deskY == y }?.student
    }

    func assignStudent(_ student: Student, to position: (x: Int16, y: Int16), context: NSManagedObjectContext) {
        // Remove existing assignment for this student in this class
        if let existing = seatAssignment(for: student) {
            context.delete(existing)
        }

        // Remove any student already at this position
        if let existingAtPosition = seatAssignmentsArray.first(where: { $0.deskX == position.x && $0.deskY == position.y }) {
            context.delete(existingAtPosition)
        }

        // Create new assignment
        let assignment = SeatAssignment(context: context)
        assignment.id = UUID()
        assignment.deskX = position.x
        assignment.deskY = position.y
        assignment.student = student
        assignment.classPeriod = self
    }

    func unassignStudent(_ student: Student, context: NSManagedObjectContext) {
        if let assignment = seatAssignment(for: student) {
            context.delete(assignment)
        }
    }

    func attendanceRecord(for student: Student, on date: Date) -> AttendanceRecord? {
        let calendar = Calendar.current
        return attendanceRecordsArray.first {
            $0.student == student && ($0.date.map { calendar.isDate($0, inSameDayAs: date) } ?? false)
        }
    }

    func attendanceRecords(for date: Date) -> [AttendanceRecord] {
        let calendar = Calendar.current
        return attendanceRecordsArray.filter { $0.date.map { calendar.isDate($0, inSameDayAs: date) } ?? false }
    }
}
