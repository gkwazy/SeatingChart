//
//  StudentPoolView.swift
//  SeatingChart
//
//  Created by GKWazy Software
//

import SwiftUI
import CoreData

struct StudentPoolView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appStateManager: AppStateManager

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Student.name, ascending: true)],
        animation: .default)
    private var allStudents: FetchedResults<Student>

    @State private var searchText = ""
    @State private var showingAddStudent = false
    @State private var selectedStudent: Student?

    var filteredStudents: [Student] {
        if searchText.isEmpty {
            return Array(allStudents)
        } else {
            return allStudents.filter { student in
                let name = student.name ?? ""
                let firstName = student.firstName ?? ""
                let lastName = student.lastName ?? ""
                let studentID = student.studentID ?? ""

                return name.localizedCaseInsensitiveContains(searchText) ||
                       firstName.localizedCaseInsensitiveContains(searchText) ||
                       lastName.localizedCaseInsensitiveContains(searchText) ||
                       studentID.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var assignedStudents: [Student] {
        filteredStudents.filter { $0.classPeriod != nil }
    }

    var unassignedStudents: [Student] {
        filteredStudents.filter { $0.classPeriod == nil }
    }

    var body: some View {
        NavigationStack {
            List {
                if !unassignedStudents.isEmpty {
                    Section("Unassigned Students (\(unassignedStudents.count))") {
                        ForEach(unassignedStudents) { student in
                            StudentRowView(student: student)
                                .onTapGesture {
                                    selectedStudent = student
                                }
                        }
                        .onDelete { offsets in
                            deleteStudents(from: unassignedStudents, at: offsets)
                        }
                    }
                }

                if !assignedStudents.isEmpty {
                    Section("Assigned to Classes (\(assignedStudents.count))") {
                        ForEach(assignedStudents) { student in
                            StudentRowView(student: student, showClass: true)
                                .onTapGesture {
                                    selectedStudent = student
                                }
                        }
                        .onDelete { offsets in
                            deleteStudents(from: assignedStudents, at: offsets)
                        }
                    }
                }

                if filteredStudents.isEmpty {
                    ContentUnavailableView(
                        "No Students",
                        systemImage: "person.slash",
                        description: Text(searchText.isEmpty ? "Add students to get started" : "No students match '\(searchText)'")
                    )
                }
            }
            .searchable(text: $searchText, prompt: "Search by name or ID")
            .navigationTitle("All Students")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddStudent = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddStudent) {
                AddStudentSheet()
            }
            .sheet(item: $selectedStudent) { student in
                EditStudentSheet(student: student)
            }
        }
    }

    private func deleteStudents(from students: [Student], at offsets: IndexSet) {
        withAnimation {
            offsets.map { students[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}

struct StudentRowView: View {
    @ObservedObject var student: Student
    @EnvironmentObject var appStateManager: AppStateManager

    var showClass: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Student photo
            if let photoData = student.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: appStateManager.privacyModeEnabled ? (PhotoManager.shared.blurImage(uiImage) ?? uiImage) : uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(student.name ?? "Unknown")
                    .font(.headline)

                HStack(spacing: 12) {
                    if let studentID = student.studentID {
                        Text(studentID)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if showClass, let className = student.classPeriod?.name {
                        Label(className, systemImage: "folder.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct AddStudentSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var studentID = ""
    @State private var selectedPhoto: UIImage?
    @State private var showingImagePicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Student Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Student ID (Optional)", text: $studentID)
                }

                Section("Photo") {
                    HStack {
                        if let photo = selectedPhoto {
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Button(action: { showingImagePicker = true }) {
                            Label("Choose Photo", systemImage: "photo")
                        }
                    }
                }
            }
            .navigationTitle("Add Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addStudent()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
        }
    }

    private func addStudent() {
        let student = Student(context: viewContext)
        student.id = UUID()
        student.firstName = firstName
        student.lastName = lastName
        student.name = "\(firstName) \(lastName)"
        student.studentID = studentID.isEmpty ? nil : studentID
        student.createdAt = Date()

        if let photo = selectedPhoto {
            student.photoData = photo.jpegData(compressionQuality: 0.7)
        }

        try? viewContext.save()
        dismiss()
    }
}

struct EditStudentSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var student: Student

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClassPeriod.name, ascending: true)],
        animation: .default)
    private var allClasses: FetchedResults<ClassPeriod>

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var studentID = ""
    @State private var selectedClassID: UUID?
    @State private var selectedPhoto: UIImage?
    @State private var showingImagePicker = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Student Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Student ID", text: $studentID)
                }

                Section("Assigned Class") {
                    Picker("Class", selection: $selectedClassID) {
                        Text("No Class").tag(nil as UUID?)
                        ForEach(allClasses) { classPeriod in
                            Text(classPeriod.name ?? "Unnamed").tag(classPeriod.id as UUID?)
                        }
                    }
                }

                Section("Photo") {
                    HStack {
                        if let photo = selectedPhoto {
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Button(action: { showingImagePicker = true }) {
                            Label("Change Photo", systemImage: "photo")
                        }
                    }
                }

                Section {
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label("Delete Student", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Edit Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
            .onAppear {
                firstName = student.firstName ?? ""
                lastName = student.lastName ?? ""
                studentID = student.studentID ?? ""
                selectedClassID = student.classPeriod?.id

                if let photoData = student.photoData {
                    selectedPhoto = UIImage(data: photoData)
                }
            }
            .confirmationDialog("Delete Student", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteStudent()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete \(student.name ?? "this student"). This action cannot be undone.")
            }
        }
    }

    private func saveChanges() {
        student.firstName = firstName
        student.lastName = lastName
        student.name = "\(firstName) \(lastName)"
        student.studentID = studentID.isEmpty ? nil : studentID

        // Update class assignment
        if let classID = selectedClassID {
            if let selectedClass = allClasses.first(where: { $0.id == classID }) {
                student.classPeriod = selectedClass
            }
        } else {
            student.classPeriod = nil
        }

        if let photo = selectedPhoto {
            student.photoData = photo.jpegData(compressionQuality: 0.7)
        }

        try? viewContext.save()
        dismiss()
    }

    private func deleteStudent() {
        viewContext.delete(student)
        try? viewContext.save()
        dismiss()
    }
}

#Preview {
    StudentPoolView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppStateManager.shared)
}
