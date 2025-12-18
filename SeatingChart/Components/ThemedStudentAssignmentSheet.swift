//
//  ThemedStudentAssignmentSheet.swift
//  SeatingChart
//
//  Extracted from MainSeatingChartView for reusability
//  Sheet for assigning students to desks
//

import SwiftUI

// MARK: - Themed Student Assignment Sheet

struct ThemedStudentAssignmentSheet: View {
    let desk: Desk
    let students: [Student]
    let assignedStudent: Student?
    let onAssign: (Student) -> Void
    let onUnassign: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredStudents: [Student] {
        if searchText.isEmpty {
            return students
        }
        return students.filter { student in
            let fullName = "\(student.firstName ?? "") \(student.lastName ?? "")"
            return fullName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.ivory
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Remove from desk option
                        if assignedStudent != nil {
                            removeFromDeskButton
                        }

                        // Search bar (only show if many students)
                        if students.count > 10 {
                            searchBar
                        }

                        // Available students section
                        availableStudentsSection
                    }
                    .padding(.bottom, Theme.Spacing.xl)
                }
            }
            .navigationTitle(assignedStudent != nil ? "Change Assignment" : "Assign Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.forest)
                }
            }
        }
    }

    // MARK: - Remove Button

    private var removeFromDeskButton: some View {
        Button(action: {
            onUnassign()
            dismiss()
        }) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "person.badge.minus")
                    .font(.system(size: 18, weight: .medium))
                Text("Remove from Desk")
                    .font(Theme.Typography.headline(15, weight: .medium))
                Spacer()
            }
            .foregroundColor(Theme.Colors.danger)
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.absentBg)
            .cornerRadius(Theme.Radius.sm)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.md)
        .accessibilityLabel("Remove student from desk")
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.Colors.slate)

            TextField("Search students", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.Colors.stone)
                }
            }
        }
        .padding(Theme.Spacing.sm)
        .background(Color.white)
        .cornerRadius(Theme.Radius.sm)
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Available Students Section

    private var availableStudentsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ThemeSectionHeader(
                filteredStudents.isEmpty ? "No Unassigned Students" : "Assign Student"
            )
            .padding(.horizontal, Theme.Spacing.md)

            if filteredStudents.isEmpty && !searchText.isEmpty {
                noResultsView
            } else {
                ForEach(filteredStudents) { student in
                    studentRow(student)
                }
            }
        }
    }

    private var noResultsView: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "person.slash")
                .font(.system(size: 32))
                .foregroundColor(Theme.Colors.stone)
            Text("No students found")
                .font(Theme.Typography.body(14))
                .foregroundColor(Theme.Colors.slate)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
    }

    private func studentRow(_ student: Student) -> some View {
        Button(action: {
            onAssign(student)
            dismiss()
        }) {
            HStack(spacing: Theme.Spacing.sm) {
                studentPhoto(student)

                Text("\(student.firstName ?? "") \(student.lastName ?? "")")
                    .font(Theme.Typography.body(16))
                    .foregroundColor(Theme.Colors.charcoal)

                Spacer()

                Image(systemName: "plus.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Theme.Colors.forest)
            }
            .padding(Theme.Spacing.sm)
            .background(Color.white)
            .cornerRadius(Theme.Radius.sm)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Spacing.md)
        .accessibilityLabel("Assign \(student.firstName ?? "") \(student.lastName ?? "") to desk")
    }

    @ViewBuilder
    private func studentPhoto(_ student: Student) -> some View {
        if let photoData = student.photoData,
           let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Theme.Colors.forest.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(student.initials ?? "?")
                        .font(Theme.Typography.headline(16, weight: .semibold))
                        .foregroundColor(Theme.Colors.forest)
                )
        }
    }
}

#Preview("Student Assignment Sheet") {
    ThemedStudentAssignmentSheet(
        desk: Desk(position: CGPoint(x: 100, y: 100), type: .rectangle),
        students: [],
        assignedStudent: nil,
        onAssign: { _ in },
        onUnassign: {}
    )
}
