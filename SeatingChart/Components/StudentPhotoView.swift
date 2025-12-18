//
//  StudentPhotoView.swift
//  SeatingChart
//
//  Refined with Schoolhouse Modern aesthetic
//

import SwiftUI

struct StudentPhotoView: View {
    let student: Student
    let size: CGFloat
    var showBorder: Bool = true
    var borderColor: Color = Theme.Colors.amber
    var borderWidth: CGFloat = 2
    @EnvironmentObject var appState: AppStateManager

    var body: some View {
        Group {
            if let photo = student.photo {
                if appState.privacyModeEnabled {
                    Image(uiImage: PhotoManager.shared.blurImage(photo) ?? photo)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                }
            } else {
                // Elegant placeholder with initials
                initialsPlaceholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(showBorder ? borderColor : .clear, lineWidth: borderWidth)
        )
        .themeShadow(Theme.Shadows.subtle)
    }

    private var initialsPlaceholder: some View {
        ZStack {
            // Gradient background based on name
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Initials text
            Text(student.initials ?? "?")
                .font(Theme.Typography.headline(size * 0.4, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private var gradientColors: [Color] {
        // Generate consistent colors based on student name
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
}

// MARK: - Convenience Initializers

extension StudentPhotoView {
    /// Standard desk thumbnail size
    static func deskThumbnail(student: Student) -> StudentPhotoView {
        StudentPhotoView(
            student: student,
            size: Constants.PhotoSize.deskThumbnail,
            showBorder: true,
            borderColor: .white,
            borderWidth: 2
        )
    }

    /// Roster row size
    static func rosterRow(student: Student) -> StudentPhotoView {
        StudentPhotoView(
            student: student,
            size: Constants.PhotoSize.rosterRow,
            showBorder: true,
            borderColor: Theme.Colors.amber,
            borderWidth: 2
        )
    }

    /// Detail view size
    static func detailView(student: Student) -> StudentPhotoView {
        StudentPhotoView(
            student: student,
            size: Constants.PhotoSize.detailView,
            showBorder: true,
            borderColor: Theme.Colors.forest,
            borderWidth: 3
        )
    }
}

// MARK: - Preview

#Preview("Student Photos") {
    let context = PersistenceController.preview.container.viewContext
    let student1 = Student(context: context, name: "John Doe")
    let student2 = Student(context: context, name: "Alice Smith")
    let student3 = Student(context: context, name: "Bob Jones")

    return VStack(spacing: Theme.Spacing.lg) {
        Text("Student Photos")
            .font(Theme.Typography.display(24))
            .foregroundColor(Theme.Colors.charcoal)

        HStack(spacing: Theme.Spacing.md) {
            StudentPhotoView(student: student1, size: 50)
            StudentPhotoView(student: student2, size: 50)
            StudentPhotoView(student: student3, size: 50)
        }

        HStack(spacing: Theme.Spacing.md) {
            StudentPhotoView.deskThumbnail(student: student1)
            StudentPhotoView.rosterRow(student: student2)
            StudentPhotoView.detailView(student: student3)
        }
    }
    .padding()
    .background(Theme.Colors.ivory)
    .environmentObject(AppStateManager.shared)
}
