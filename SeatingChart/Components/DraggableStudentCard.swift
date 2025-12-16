//
//  DraggableStudentCard.swift
//  SeatingChart
//
//  Created by Claude
//

import SwiftUI
import CoreTransferable
import UniformTypeIdentifiers

struct DraggableStudentCard: View {
    let student: Student
    let isAssigned: Bool
    @EnvironmentObject var appState: AppStateManager

    var body: some View {
        HStack(spacing: 12) {
            StudentPhotoView(student: student, size: 40)

            Text(student.name ?? "Unknown")
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            if isAssigned {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(Constants.smallCornerRadius)
    }
}

// Transfer representation for drag and drop
struct StudentTransfer: Codable, Transferable {
    let studentID: UUID

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .studentTransfer)
    }
}

extension UTType {
    static let studentTransfer = UTType(exportedAs: "com.seatingchart.student")
}

struct DraggableStudentCard_Previews: PreviewProvider {
    static var previews: some View {
        let controller = PersistenceController.preview
        let context = controller.container.viewContext
        let student = Student(context: context, name: "Jane Smith")

        return VStack {
            DraggableStudentCard(student: student, isAssigned: false)
            DraggableStudentCard(student: student, isAssigned: true)
        }
        .padding()
        .environmentObject(AppStateManager.shared)
        .environment(\.managedObjectContext, context)
    }
}
