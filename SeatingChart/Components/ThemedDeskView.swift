//
//  ThemedDeskView.swift
//  SeatingChart
//
//  Extracted from MainSeatingChartView for reusability
//  Individual desk rendering with student info and attendance status
//

import SwiftUI

// MARK: - Themed Desk View

struct ThemedDeskView: View {
    let desk: Desk
    let student: Student?
    let status: AttendanceStatus?
    let showPhoto: Bool
    let privacyMode: Bool
    let isTakingAttendance: Bool
    let showAttendanceColors: Bool

    @State private var isHovered = false
    @State private var appeared = false

    private var deskStyle: ThemeDeskStyle {
        if let status = status, (isTakingAttendance || showAttendanceColors) {
            return ThemeDeskStyle.attendance(status)
        } else if student != nil {
            return ThemeDeskStyle.standard(occupied: true)
        } else {
            return ThemeDeskStyle.standard(occupied: false)
        }
    }

    var body: some View {
        ZStack {
            // Desk shape with wood-like appearance
            if student != nil {
                occupiedDeskBackground
            } else {
                emptyDeskBackground
            }

            // Front-of-classroom indicator
            frontIndicator

            // Student content or empty hint
            if let student = student {
                studentContent(student)
            } else {
                emptyDeskHint
            }
        }
        .frame(width: desk.size.width, height: desk.size.height)
        .contentShape(Rectangle())
        .rotationEffect(desk.rotation)
        .scaleEffect(appeared ? 1.0 : 0.8)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(Theme.Animation.bouncy.delay(Double.random(in: 0...0.3))) {
                appeared = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to \(student != nil ? "view or reassign" : "assign") student")
    }

    // MARK: - Desk Backgrounds

    private var occupiedDeskBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        LinearGradient(
                            colors: [deskStyle.borderColor, deskStyle.borderColor.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2.5
                    )
            )
            .shadow(color: deskStyle.shadowColor, radius: 8, x: 0, y: 4)
    }

    private var emptyDeskBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Theme.Colors.linen.opacity(0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        Theme.Colors.stone,
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
            )
    }

    // MARK: - Front Indicator

    private var frontIndicator: some View {
        VStack {
            Spacer()
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    student != nil
                        ? Theme.Colors.forest.opacity(0.6)
                        : Theme.Colors.stone.opacity(0.4)
                )
                .frame(width: desk.size.width * 0.5, height: 3)
                .padding(.bottom, 5)
        }
    }

    // MARK: - Student Content

    private func studentContent(_ student: Student) -> some View {
        VStack(spacing: 4) {
            if showPhoto {
                studentPhoto(student)
            }

            Text(student.name ?? "Unknown")
                .font(Theme.Typography.caption(11, weight: .semibold))
                .foregroundColor(Theme.Colors.charcoal)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let status = status, (isTakingAttendance || showAttendanceColors) {
                statusBadge(status)
            }
        }
        .padding(8)
    }

    @ViewBuilder
    private func studentPhoto(_ student: Student) -> some View {
        if let photoData = student.photoData, let uiImage = UIImage(data: photoData) {
            Image(uiImage: privacyMode ? (PhotoManager.shared.blurImage(uiImage) ?? uiImage) : uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        } else {
            Circle()
                .fill(Theme.Colors.forest.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(student.initials ?? "?")
                        .font(Theme.Typography.headline(14, weight: .semibold))
                        .foregroundColor(Theme.Colors.forest)
                )
        }
    }

    private func statusBadge(_ status: AttendanceStatus) -> some View {
        Text(status.displayName)
            .font(Theme.Typography.caption(9, weight: .bold))
            .foregroundColor(statusTextColor(for: status))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusBackgroundColor(for: status))
            .cornerRadius(4)
    }

    // MARK: - Empty Desk Hint

    private var emptyDeskHint: some View {
        VStack(spacing: 4) {
            Image(systemName: "plus.circle")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Theme.Colors.stone)

            Text("Tap to assign")
                .font(Theme.Typography.caption(9))
                .foregroundColor(Theme.Colors.stone)
        }
    }

    // MARK: - Status Colors

    private func statusTextColor(for status: AttendanceStatus) -> Color {
        switch status {
        case .present: return Theme.Colors.success
        case .tardy: return Theme.Colors.warning
        case .absent: return Theme.Colors.danger
        }
    }

    private func statusBackgroundColor(for status: AttendanceStatus) -> Color {
        switch status {
        case .present: return Theme.Colors.presentBg
        case .tardy: return Theme.Colors.tardyBg
        case .absent: return Theme.Colors.absentBg
        }
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        if let student = student {
            var description = "Desk with \(student.name ?? "unknown student")"
            if let status = status, (isTakingAttendance || showAttendanceColors) {
                description += ", marked \(status.displayName)"
            }
            return description
        } else {
            return "Empty desk, tap to assign student"
        }
    }
}

#Preview("Themed Desk Views") {
    let desk = Desk(position: CGPoint(x: 100, y: 100), type: .rectangle)

    VStack(spacing: 30) {
        ThemedDeskView(
            desk: desk,
            student: nil,
            status: nil,
            showPhoto: true,
            privacyMode: false,
            isTakingAttendance: false,
            showAttendanceColors: false
        )

        // Note: Preview with actual Student would need Core Data context
    }
    .padding()
    .background(Theme.Colors.ivory)
}
