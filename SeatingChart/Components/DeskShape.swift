//
//  DeskShape.swift
//  SeatingChart
//
//  Created by Claude
//

import SwiftUI

struct DeskShape: View {
    let desk: Desk
    let students: [Student]
    let isSelected: Bool
    let showStudents: Bool
    let showNames: Bool
    let privacyMode: Bool

    init(
        desk: Desk,
        students: [Student] = [],
        isSelected: Bool = false,
        showStudents: Bool = true,
        showNames: Bool = true,
        privacyMode: Bool = false
    ) {
        self.desk = desk
        self.students = students
        self.isSelected = isSelected
        self.showStudents = showStudents
        self.showNames = showNames
        self.privacyMode = privacyMode
    }

    var body: some View {
        ZStack {
            // Desk shape background
            deskBackground

            // Student content
            if showStudents && !students.isEmpty {
                studentContent
            } else if !showStudents || students.isEmpty {
                emptyDeskIcon
            }
        }
        .frame(width: desk.size.width, height: desk.size.height)
        .rotationEffect(desk.rotation)
    }

    @ViewBuilder
    private var deskBackground: some View {
        Group {
            switch desk.type {
            case .rectangle, .longRectangle:
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(borderColor, lineWidth: isSelected ? 3 : 2)
                    )

            case .square:
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(borderColor, lineWidth: isSelected ? 3 : 2)
                    )

            case .trapezoid:
                TrapezoidShape()
                    .fill(backgroundColor)
                    .overlay(
                        TrapezoidShape()
                            .strokeBorder(borderColor, lineWidth: isSelected ? 3 : 2)
                    )

            case .circle:
                Circle()
                    .fill(backgroundColor)
                    .overlay(
                        Circle()
                            .strokeBorder(borderColor, lineWidth: isSelected ? 3 : 2)
                    )
            }
        }
        .shadow(
            color: shadowColor,
            radius: isSelected ? 8 : 4,
            x: 0,
            y: isSelected ? 4 : 2
        )
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.blue.opacity(0.2)
        } else if desk.isOccupied {
            return Color(.systemBackground)
        } else {
            return Color(.systemGray6)
        }
    }

    private var borderColor: Color {
        if isSelected {
            return .blue
        } else if desk.isOccupied {
            return Color(.systemGray3)
        } else {
            return Color(.systemGray4)
        }
    }

    private var shadowColor: Color {
        isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.15)
    }

    @ViewBuilder
    private var studentContent: some View {
        if desk.type == .longRectangle {
            // Long table layout - multiple students in a row
            HStack(spacing: 8) {
                ForEach(students) { student in
                    studentView(for: student)
                }
            }
            .padding(8)
        } else if desk.type == .circle && students.count > 1 {
            // Circle table - arrange around
            ZStack {
                ForEach(Array(students.enumerated()), id: \.element.id) { index, student in
                    studentView(for: student)
                        .offset(circleOffset(for: index, total: students.count))
                }
            }
        } else {
            // Single student or default
            if let student = students.first {
                studentView(for: student)
            }
        }
    }

    @ViewBuilder
    private func studentView(for student: Student) -> some View {
        VStack(spacing: 4) {
            if let photoData = student.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: privacyMode ? (PhotoManager.shared.blurImage(uiImage) ?? uiImage) : uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.gray)
            }

            if showNames && !privacyMode {
                if let firstName = student.firstName {
                    Text(firstName)
                        .font(.system(size: 9))
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
            }
        }
    }

    private var emptyDeskIcon: some View {
        VStack(spacing: 4) {
            Image(systemName: "studentdesk")
                .font(.system(size: desk.size.width / 3))
                .foregroundColor(.gray.opacity(0.4))

            if desk.capacity > 1 {
                Text("\(desk.capacity) seats")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func circleOffset(for index: Int, total: Int) -> CGSize {
        let angle = (2 * Double.pi / Double(total)) * Double(index) - Double.pi / 2
        let radius = min(desk.size.width, desk.size.height) * 0.3
        return CGSize(
            width: CGFloat(cos(angle)) * radius,
            height: CGFloat(sin(angle)) * radius
        )
    }
}

// Trapezoid shape for group desks
struct TrapezoidShape: InsettableShape {
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let inset = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let topWidth = inset.width * 0.7
        let offset = (inset.width - topWidth) / 2

        path.move(to: CGPoint(x: inset.minX + offset, y: inset.minY))
        path.addLine(to: CGPoint(x: inset.maxX - offset, y: inset.minY))
        path.addLine(to: CGPoint(x: inset.maxX, y: inset.maxY))
        path.addLine(to: CGPoint(x: inset.minX, y: inset.maxY))
        path.closeSubpath()

        return path
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}

#Preview("Different Desk Types") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            DeskShape(desk: Desk(type: .rectangle))
            DeskShape(desk: Desk(type: .square))
            DeskShape(desk: Desk(type: .trapezoid))
        }

        HStack(spacing: 20) {
            DeskShape(desk: Desk(type: .circle))
            DeskShape(desk: Desk(type: .longRectangle), isSelected: true)
        }
    }
    .padding()
}
