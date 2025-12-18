//
//  DeskShape.swift
//  SeatingChart
//
//  Refined with Schoolhouse Modern aesthetic
//

import SwiftUI

struct DeskShape: View {
    let desk: Desk
    let students: [Student]
    let isSelected: Bool
    let showStudents: Bool
    let showNames: Bool
    let privacyMode: Bool
    var attendanceStatus: AttendanceStatus?

    init(
        desk: Desk,
        students: [Student] = [],
        isSelected: Bool = false,
        showStudents: Bool = true,
        showNames: Bool = true,
        privacyMode: Bool = false,
        attendanceStatus: AttendanceStatus? = nil
    ) {
        self.desk = desk
        self.students = students
        self.isSelected = isSelected
        self.showStudents = showStudents
        self.showNames = showNames
        self.privacyMode = privacyMode
        self.attendanceStatus = attendanceStatus
    }

    private var deskStyle: ThemeDeskStyle {
        if isSelected {
            return ThemeDeskStyle.selected()
        } else if let status = attendanceStatus {
            return ThemeDeskStyle.attendance(status)
        } else {
            return ThemeDeskStyle.standard(occupied: desk.isOccupied)
        }
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
        let cornerRadius: CGFloat = desk.type == .square ? 6 : 8

        Group {
            switch desk.type {
            case .rectangle, .longRectangle:
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(deskStyle.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(deskStyle.borderColor, lineWidth: isSelected ? 3 : 2)
                    )

            case .square:
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(deskStyle.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(deskStyle.borderColor, lineWidth: isSelected ? 3 : 2)
                    )

            case .trapezoid:
                TrapezoidShape()
                    .fill(deskStyle.backgroundColor)
                    .overlay(
                        TrapezoidShape()
                            .strokeBorder(deskStyle.borderColor, lineWidth: isSelected ? 3 : 2)
                    )

            case .circle:
                Circle()
                    .fill(deskStyle.backgroundColor)
                    .overlay(
                        Circle()
                            .strokeBorder(deskStyle.borderColor, lineWidth: isSelected ? 3 : 2)
                    )
            }
        }
        .shadow(
            color: deskStyle.shadowColor,
            radius: isSelected ? 8 : 4,
            x: 0,
            y: isSelected ? 4 : 2
        )
    }

    @ViewBuilder
    private var studentContent: some View {
        if desk.type == .longRectangle {
            // Long table layout - multiple students in a row
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(students) { student in
                    studentView(for: student)
                }
            }
            .padding(Theme.Spacing.xs)
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
        VStack(spacing: 3) {
            // Photo or initials placeholder
            studentPhoto(for: student)

            // Name label
            if showNames && !privacyMode {
                if let firstName = student.firstName {
                    Text(firstName)
                        .font(Theme.Typography.caption(9, weight: .semibold))
                        .foregroundColor(Theme.Colors.charcoal)
                        .lineLimit(1)
                }
            }
        }
    }

    @ViewBuilder
    private func studentPhoto(for student: Student) -> some View {
        if let photoData = student.photoData, let uiImage = UIImage(data: photoData) {
            Image(uiImage: privacyMode ? (PhotoManager.shared.blurImage(uiImage) ?? uiImage) : uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: Constants.PhotoSize.deskThumbnail, height: Constants.PhotoSize.deskThumbnail)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .themeShadow(Theme.Shadows.subtle)
        } else {
            // Initials placeholder
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: placeholderGradient(for: student),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(student.initials ?? "?")
                    .font(Theme.Typography.headline(14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: Constants.PhotoSize.deskThumbnail, height: Constants.PhotoSize.deskThumbnail)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .themeShadow(Theme.Shadows.subtle)
        }
    }

    private func placeholderGradient(for student: Student) -> [Color] {
        let name = student.name ?? "Unknown"
        let hash = abs(name.hashValue)
        let colorPairs: [[Color]] = [
            [Theme.Colors.forest, Theme.Colors.forestLight],
            [Theme.Colors.amber, Theme.Colors.terracotta],
            [Theme.Colors.forestMuted, Theme.Colors.forest],
            [Theme.Colors.terracotta, Theme.Colors.amber],
            [Theme.Colors.slate, Theme.Colors.charcoal]
        ]
        return colorPairs[hash % colorPairs.count]
    }

    private var emptyDeskIcon: some View {
        VStack(spacing: 3) {
            Image(systemName: "studentdesk")
                .font(.system(size: desk.size.width / 3.5, weight: .light))
                .foregroundColor(Theme.Colors.stone)

            if desk.capacity > 1 {
                Text("\(desk.capacity) seats")
                    .font(Theme.Typography.caption(8))
                    .foregroundColor(Theme.Colors.slate)
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
