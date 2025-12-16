//
//  TestDataGenerator.swift
//  SeatingChart
//
//  Created by Claude
//

import Foundation
import CoreData
import UIKit

struct TestDataGenerator {

    static let studentNames: [(firstName: String, lastName: String)] = [
        ("Emma", "Johnson"),
        ("Liam", "Williams"),
        ("Olivia", "Brown"),
        ("Noah", "Jones"),
        ("Ava", "Garcia"),
        ("Ethan", "Martinez"),
        ("Sophia", "Davis"),
        ("Mason", "Rodriguez"),
        ("Isabella", "Wilson"),
        ("William", "Anderson"),
        ("Mia", "Thomas"),
        ("James", "Taylor"),
        ("Charlotte", "Moore"),
        ("Benjamin", "Jackson"),
        ("Amelia", "Martin"),
        ("Lucas", "Lee"),
        ("Harper", "Perez"),
        ("Henry", "White"),
        ("Evelyn", "Harris"),
        ("Alexander", "Clark")
    ]

    /// Creates a Math class with 20 test students
    static func generateMathClassWithStudents(context: NSManagedObjectContext) {
        // Check if Math class already exists
        let fetchRequest: NSFetchRequest<ClassPeriod> = ClassPeriod.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", "Math")

        var mathClass: ClassPeriod

        if let existing = try? context.fetch(fetchRequest).first {
            print("✅ Math class already exists, adding students to it")
            mathClass = existing
        } else {
            // Create Math class
            mathClass = ClassPeriod(context: context)
            mathClass.id = UUID()
            mathClass.name = "Math"
            mathClass.subject = "Mathematics"
            mathClass.createdAt = Date()
            print("✅ Created new Math class")
        }

        // Create 20 students
        for (index, name) in studentNames.enumerated() {
            let student = Student(context: context)
            student.id = UUID()
            student.firstName = name.firstName
            student.lastName = name.lastName
            student.name = "\(name.firstName) \(name.lastName)"
            student.studentID = String(format: "S%04d", 1000 + index)
            student.createdAt = Date()
            student.classPeriod = mathClass

            // Generate a placeholder photo with initials
            if let placeholderImage = generatePlaceholderImage(initials: "\(name.firstName.first!)\(name.lastName.first!)") {
                student.photoData = placeholderImage.jpegData(compressionQuality: 0.7)
            }

            print("  ✓ Added student: \(student.name ?? "Unknown") (ID: \(student.studentID ?? ""))")
        }

        // Save context
        do {
            try context.save()
            print("🎉 Successfully created Math class with 20 students!")
        } catch {
            print("❌ Error saving test data: \(error.localizedDescription)")
        }
    }

    /// Generates a placeholder image with initials
    private static func generatePlaceholderImage(initials: String) -> UIImage? {
        let size = CGSize(width: 200, height: 200)
        let colors: [UIColor] = [
            .systemBlue, .systemGreen, .systemOrange, .systemPurple,
            .systemPink, .systemTeal, .systemIndigo, .systemCyan
        ]
        let randomColor = colors.randomElement() ?? .systemBlue

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Draw circle background
        context.setFillColor(randomColor.cgColor)
        context.fillEllipse(in: CGRect(origin: .zero, size: size))

        // Draw initials
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 80, weight: .bold),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]

        let textSize = initials.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )

        initials.draw(in: textRect, withAttributes: attributes)

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// Clears all students from Math class
    static func clearMathClassStudents(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<ClassPeriod> = ClassPeriod.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", "Math")

        guard let mathClass = try? context.fetch(fetchRequest).first else {
            print("⚠️ Math class not found")
            return
        }

        if let students = mathClass.students as? Set<Student> {
            for student in students {
                context.delete(student)
            }
        }

        do {
            try context.save()
            print("🗑️ Cleared all students from Math class")
        } catch {
            print("❌ Error clearing students: \(error.localizedDescription)")
        }
    }

    /// Deletes Math class entirely
    static func deleteMathClass(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<ClassPeriod> = ClassPeriod.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", "Math")

        guard let mathClass = try? context.fetch(fetchRequest).first else {
            print("⚠️ Math class not found")
            return
        }

        context.delete(mathClass)

        do {
            try context.save()
            print("🗑️ Deleted Math class")
        } catch {
            print("❌ Error deleting class: \(error.localizedDescription)")
        }
    }
}
