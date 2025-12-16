//
//  StudentRosterView.swift
//  SeatingChart
//
//  Created on 2025-11-29.
//

import SwiftUI
import PhotosUI
import CoreData

struct StudentRosterView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var classPeriod: ClassPeriod

    @State private var showingAddStudent = false
    @State private var searchText = ""

    var students: [Student] {
        let studentSet = classPeriod.students as? Set<Student> ?? []
        return studentSet.sorted { ($0.lastName ?? "") < ($1.lastName ?? "") }
    }

    var filteredStudents: [Student] {
        if searchText.isEmpty {
            return students
        } else {
            return students.filter { student in
                let fullName = "\(student.firstName ?? "") \(student.lastName ?? "")"
                return fullName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        List {
            ForEach(filteredStudents) { student in
                NavigationLink(destination: StudentDetailView(student: student)) {
                    StudentRow(student: student)
                }
            }
            .onDelete(perform: deleteStudents)
        }
        .searchable(text: $searchText, prompt: "Search students")
        .navigationTitle("Student Roster")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddStudent = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddStudent) {
            AddStudentView(classPeriod: classPeriod, isPresented: $showingAddStudent)
        }
        .overlay {
            if students.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)

                    Text("No Students Yet")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Tap the + button to add students")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func deleteStudents(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredStudents[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                print("Error deleting student: \(error.localizedDescription)")
            }
        }
    }
}

struct StudentRow: View {
    let student: Student

    var body: some View {
        HStack(spacing: 12) {
            if let photoData = student.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
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
                Text("\(student.firstName ?? "") \(student.lastName ?? "")")
                    .font(.headline)

                if let studentID = student.studentID, !studentID.isEmpty {
                    Text("ID: \(studentID)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct AddStudentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var classPeriod: ClassPeriod
    @Binding var isPresented: Bool

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var studentID = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Student Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Student ID (Optional)", text: $studentID)
                }

                Section(header: Text("Photo")) {
                    HStack {
                        if let photoData = photoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
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

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Text(photoData == nil ? "Add Photo" : "Change Photo")
                        }
                    }
                }
            }
            .navigationTitle("Add Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addStudent()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
    }

    private func addStudent() {
        let student = Student(context: viewContext)
        student.id = UUID()
        student.firstName = firstName
        student.lastName = lastName
        student.studentID = studentID.isEmpty ? nil : studentID
        student.photoData = photoData
        student.classPeriod = classPeriod

        do {
            try viewContext.save()
            isPresented = false
        } catch {
            print("Error saving student: \(error.localizedDescription)")
        }
    }
}

struct StudentDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var student: Student

    @State private var isEditing = false

    var attendanceRecords: [AttendanceRecord] {
        let records = student.attendanceRecords as? Set<AttendanceRecord> ?? []
        return records.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    var attendanceStats: (present: Int, absent: Int, tardy: Int) {
        var present = 0
        var absent = 0
        var tardy = 0

        for record in attendanceRecords {
            switch record.attendanceStatus {
            case .present:
                present += 1
            case .absent:
                absent += 1
            case .tardy:
                tardy += 1
            }
        }
        return (present, absent, tardy)
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    if let photoData = student.photoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.vertical)
            }

            Section(header: Text("Information")) {
                HStack {
                    Text("Name")
                    Spacer()
                    Text("\(student.firstName ?? "") \(student.lastName ?? "")")
                        .foregroundColor(.secondary)
                }

                if let studentID = student.studentID, !studentID.isEmpty {
                    HStack {
                        Text("Student ID")
                        Spacer()
                        Text(studentID)
                            .foregroundColor(.secondary)
                    }
                }

                if let classPeriod = student.classPeriod {
                    HStack {
                        Text("Class")
                        Spacer()
                        Text(classPeriod.name ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Attendance Summary
            Section(header: Text("Attendance Summary")) {
                HStack {
                    AttendanceStatView(count: attendanceStats.present, label: "Present", color: .green)
                    Spacer()
                    AttendanceStatView(count: attendanceStats.absent, label: "Absent", color: .red)
                    Spacer()
                    AttendanceStatView(count: attendanceStats.tardy, label: "Tardy", color: .yellow)
                }
                .padding(.vertical, 8)
            }

            // Attendance History
            Section(header: Text("Attendance History")) {
                if attendanceRecords.isEmpty {
                    Text("No attendance records yet")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(attendanceRecords, id: \.id) { record in
                        HStack {
                            Image(systemName: record.attendanceStatus.icon)
                                .foregroundColor(record.attendanceStatus.color)

                            Text(record.date?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown date")

                            Spacer()

                            Text(record.attendanceStatus.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(record.attendanceStatus.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(record.attendanceStatus.color.opacity(0.15))
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .navigationTitle("Student Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditStudentView(student: student, isPresented: $isEditing)
        }
    }
}

struct AttendanceStatView: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 60)
    }
}

struct EditStudentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var student: Student
    @Binding var isPresented: Bool

    @State private var firstName: String
    @State private var lastName: String
    @State private var studentID: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    init(student: Student, isPresented: Binding<Bool>) {
        self.student = student
        self._isPresented = isPresented
        self._firstName = State(initialValue: student.firstName ?? "")
        self._lastName = State(initialValue: student.lastName ?? "")
        self._studentID = State(initialValue: student.studentID ?? "")
        self._photoData = State(initialValue: student.photoData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Student Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Student ID (Optional)", text: $studentID)
                }

                Section(header: Text("Photo")) {
                    HStack {
                        if let photoData = photoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
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

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Text(photoData == nil ? "Add Photo" : "Change Photo")
                        }
                    }
                }
            }
            .navigationTitle("Edit Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
    }

    private func saveChanges() {
        student.firstName = firstName
        student.lastName = lastName
        student.studentID = studentID.isEmpty ? nil : studentID
        student.photoData = photoData

        do {
            try viewContext.save()
            isPresented = false
        } catch {
            print("Error saving changes: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let classPeriod = ClassPeriod(context: context)
    classPeriod.id = UUID()
    classPeriod.name = "Period 1"
    classPeriod.subject = "Math"

    return NavigationStack {
        StudentRosterView(classPeriod: classPeriod)
            .environment(\.managedObjectContext, context)
    }
}
