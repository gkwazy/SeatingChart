//
//  SeatingRule+Extensions.swift
//  SeatingChart
//
//  Extensions for the SeatingRule Core Data entity
//  Manages student seating constraints (who can't sit together)
//

import Foundation
import CoreData
import SwiftUI

// MARK: - Rule Type Enum

enum SeatingRuleType: String, CaseIterable, Identifiable {
    case keepApart = "keep_apart"
    case keepTogether = "keep_together"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .keepApart: return "Keep Apart"
        case .keepTogether: return "Keep Together"
        }
    }

    var icon: String {
        switch self {
        case .keepApart: return "arrow.left.arrow.right"
        case .keepTogether: return "link"
        }
    }

    var description: String {
        switch self {
        case .keepApart: return "These students should not sit next to each other"
        case .keepTogether: return "These students should sit near each other"
        }
    }

    var color: Color {
        switch self {
        case .keepApart: return Theme.Colors.coral
        case .keepTogether: return Theme.Colors.mint
        }
    }
}

// MARK: - SeatingRule Extension

extension SeatingRule {

    /// The type of seating rule
    var ruleTypeEnum: SeatingRuleType {
        get {
            SeatingRuleType(rawValue: ruleType ?? "keep_apart") ?? .keepApart
        }
        set {
            ruleType = newValue.rawValue
        }
    }

    /// Display string for the rule
    var displayDescription: String {
        let studentAName = studentA?.firstName ?? "Student"
        let studentBName = studentB?.firstName ?? "Student"

        switch ruleTypeEnum {
        case .keepApart:
            return "\(studentAName) and \(studentBName) should not sit together"
        case .keepTogether:
            return "\(studentAName) and \(studentBName) should sit near each other"
        }
    }

    /// Short display string
    var shortDescription: String {
        let studentAName = studentA?.firstName ?? "?"
        let studentBName = studentB?.firstName ?? "?"
        return "\(studentAName) ↔ \(studentBName)"
    }

    /// Check if this rule involves a specific student
    func involves(student: Student) -> Bool {
        return studentA == student || studentB == student
    }

    /// Check if this rule involves two specific students
    func involves(studentOne: Student, studentTwo: Student) -> Bool {
        return (studentA == studentOne && studentB == studentTwo) ||
               (studentA == studentTwo && studentB == studentOne)
    }

    /// Get the other student in this rule
    func otherStudent(from student: Student) -> Student? {
        if studentA == student { return studentB }
        if studentB == student { return studentA }
        return nil
    }

    // MARK: - Factory Methods

    /// Create a new seating rule
    static func create(
        context: NSManagedObjectContext,
        studentA: Student,
        studentB: Student,
        classPeriod: ClassPeriod,
        type: SeatingRuleType = .keepApart,
        note: String? = nil
    ) -> SeatingRule {
        let rule = SeatingRule(context: context)
        rule.id = UUID()
        rule.studentA = studentA
        rule.studentB = studentB
        rule.classPeriod = classPeriod
        rule.ruleType = type.rawValue
        rule.note = note
        rule.isActive = true
        rule.createdAt = Date()
        return rule
    }

    /// Check if a rule already exists between two students
    static func ruleExists(
        context: NSManagedObjectContext,
        studentA: Student,
        studentB: Student,
        classPeriod: ClassPeriod
    ) -> Bool {
        let request: NSFetchRequest<SeatingRule> = SeatingRule.fetchRequest()
        request.predicate = NSPredicate(
            format: "classPeriod == %@ AND ((studentA == %@ AND studentB == %@) OR (studentA == %@ AND studentB == %@))",
            classPeriod, studentA, studentB, studentB, studentA
        )
        request.fetchLimit = 1

        let count = (try? context.count(for: request)) ?? 0
        return count > 0
    }

    /// Fetch all active rules for a class period
    static func fetchActiveRules(
        context: NSManagedObjectContext,
        classPeriod: ClassPeriod
    ) -> [SeatingRule] {
        let request: NSFetchRequest<SeatingRule> = SeatingRule.fetchRequest()
        request.predicate = NSPredicate(
            format: "classPeriod == %@ AND isActive == YES",
            classPeriod
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \SeatingRule.createdAt, ascending: false)
        ]

        return (try? context.fetch(request)) ?? []
    }

    /// Get all students that a given student cannot sit next to
    static func getIncompatibleStudents(
        context: NSManagedObjectContext,
        student: Student,
        classPeriod: ClassPeriod
    ) -> Set<Student> {
        let rules = fetchActiveRules(context: context, classPeriod: classPeriod)
        var incompatible = Set<Student>()

        for rule in rules where rule.ruleTypeEnum == .keepApart {
            if let other = rule.otherStudent(from: student) {
                incompatible.insert(other)
            }
        }

        return incompatible
    }

    /// Check if two students can sit next to each other
    static func canSitTogether(
        context: NSManagedObjectContext,
        studentA: Student,
        studentB: Student,
        classPeriod: ClassPeriod
    ) -> Bool {
        let request: NSFetchRequest<SeatingRule> = SeatingRule.fetchRequest()
        request.predicate = NSPredicate(
            format: "classPeriod == %@ AND isActive == YES AND ruleType == %@ AND ((studentA == %@ AND studentB == %@) OR (studentA == %@ AND studentB == %@))",
            classPeriod, SeatingRuleType.keepApart.rawValue, studentA, studentB, studentB, studentA
        )
        request.fetchLimit = 1

        let count = (try? context.count(for: request)) ?? 0
        return count == 0
    }
}

// MARK: - ClassPeriod Extension for Rules

extension ClassPeriod {

    /// Array of seating rules for this class
    var seatingRulesArray: [SeatingRule] {
        let set = seatingRules as? Set<SeatingRule> ?? []
        return set.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    /// Active seating rules only
    var activeSeatingRules: [SeatingRule] {
        seatingRulesArray.filter { $0.isActive }
    }

    /// Count of active rules
    var activeRuleCount: Int {
        activeSeatingRules.count
    }

    /// Check if any rules exist for this class
    var hasSeatingRules: Bool {
        !seatingRulesArray.isEmpty
    }
}

// MARK: - Student Extension for Rules

extension Student {

    /// All seating rules involving this student
    var allSeatingRules: [SeatingRule] {
        let rulesA = rulesAsStudentA as? Set<SeatingRule> ?? []
        let rulesB = rulesAsStudentB as? Set<SeatingRule> ?? []
        return Array(rulesA.union(rulesB)).sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    /// Students this student cannot sit next to (in the current class)
    func incompatibleStudents(in classPeriod: ClassPeriod) -> [Student] {
        allSeatingRules
            .filter { $0.classPeriod == classPeriod && $0.isActive && $0.ruleTypeEnum == .keepApart }
            .compactMap { $0.otherStudent(from: self) }
    }

    /// Count of incompatible students
    func incompatibleStudentCount(in classPeriod: ClassPeriod) -> Int {
        incompatibleStudents(in: classPeriod).count
    }
}
