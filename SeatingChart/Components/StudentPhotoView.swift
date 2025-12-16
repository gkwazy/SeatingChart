//
//  StudentPhotoView.swift
//  SeatingChart
//
//  Created by Claude
//

import SwiftUI

struct StudentPhotoView: View {
    let student: Student
    let size: CGFloat
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
                Image(uiImage: PhotoManager.shared.generatePlaceholder(for: student.name ?? "Unknown"))
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

struct StudentPhotoView_Previews: PreviewProvider {
    static var previews: some View {
        let controller = PersistenceController.preview
        let context = controller.container.viewContext
        let student = Student(context: context, name: "John Doe")

        return StudentPhotoView(student: student, size: 50)
            .environmentObject(AppStateManager.shared)
            .environment(\.managedObjectContext, context)
    }
}
