//
//  ContentView.swift
//  SeatingChart
//
//  Created by Garret Wasden on 11/29/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appStateManager: AppStateManager 

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClassPeriod.name, ascending: true)],
        animation: .default)
    private var classPeriods: FetchedResults<ClassPeriod>

    @State private var showingAddClass = false
    @State private var showingStudentPool = false
    @State private var editingClass: ClassPeriod?

    var body: some View {
        NavigationStack {
            Group {
                if classPeriods.isEmpty {
                    // Empty state
                    VStack(spacing: 24) {
                        Image(systemName: "studentdesk")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)

                        Text("Welcome to Seating Chart")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Get started by creating your first class")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button(action: { showingAddClass = true }) {
                            Label("Create First Class", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.top)
                    }
                    .padding()
                } else {
                    // List of classes
                    List {
                        ForEach(classPeriods) { classPeriod in
                            NavigationLink(destination: MainSeatingChartView(classPeriod: classPeriod)) {
                                ClassPeriodRow(classPeriod: classPeriod)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive, action: { deleteClass(classPeriod) }) {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button(action: { editingClass = classPeriod }) {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            .contextMenu {
                                Button(action: { editingClass = classPeriod }) {
                                    Label("Edit Class", systemImage: "pencil")
                                }

                                Button(role: .destructive, action: { deleteClass(classPeriod) }) {
                                    Label("Delete Class", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Classes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingStudentPool = true }) {
                        VStack(spacing: 2) {
                            Image(systemName: "person.2")
                            Text("Students")
                                .font(.caption2)
                        }
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showingAddClass = true }) {
                        VStack(spacing: 2) {
                            Image(systemName: "plus")
                            Text("Add")
                                .font(.caption2)
                        }
                    }

                    NavigationLink(destination: SettingsView()) {
                        VStack(spacing: 2) {
                            Image(systemName: "gearshape")
                            Text("Settings")
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddClass) {
            AddClassSheet()
        }
        .sheet(isPresented: $showingStudentPool) {
            StudentPoolView()
        }
        .sheet(item: $editingClass) { classPeriod in
            EditClassSheet(classPeriod: classPeriod)
        }
    }

    private func deleteClass(_ classPeriod: ClassPeriod) {
        withAnimation {
            // Students are now preserved - just remove the class relationship
            if let students = classPeriod.students as? Set<Student> {
                for student in students {
                    student.classPeriod = nil
                }
            }

            viewContext.delete(classPeriod)
            try? viewContext.save()
        }
    }
}

struct ClassPeriodRow: View {
    @ObservedObject var classPeriod: ClassPeriod

    var studentCount: Int {
        (classPeriod.students as? Set<Student>)?.count ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(classPeriod.name ?? "Unnamed Class")
                .font(.headline)

            HStack(spacing: 16) {
                Label("\(studentCount) students", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let activeLayout = (classPeriod.classrooms as? Set<Classroom>)?.first(where: { $0.isActive }) {
                    Label(activeLayout.name ?? "Layout", systemImage: "square.grid.3x3")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddClassSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var className = ""
    @State private var classSubject = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Class Details") {
                    TextField("Class Name (e.g., Period 1)", text: $className)
                    TextField("Subject (e.g., Math)", text: $classSubject)
                }
            }
            .navigationTitle("New Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createClass()
                    }
                    .disabled(className.isEmpty)
                }
            }
        }
    }

    private func createClass() {
        let newClass = ClassPeriod(context: viewContext)
        newClass.id = UUID()
        newClass.name = className
        newClass.subject = classSubject.isEmpty ? nil : classSubject
        newClass.createdAt = Date()

        try? viewContext.save()
        dismiss()
    }
}

struct EditClassSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var classPeriod: ClassPeriod

    @State private var className = ""
    @State private var classSubject = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Class Details") {
                    TextField("Class Name", text: $className)
                    TextField("Subject", text: $classSubject)
                }

                Section("Info") {
                    HStack {
                        Text("Students")
                        Spacer()
                        Text("\((classPeriod.students as? Set<Student>)?.count ?? 0)")
                            .foregroundColor(.secondary)
                    }

                    if let createdAt = classPeriod.createdAt {
                        HStack {
                            Text("Created")
                            Spacer()
                            Text(createdAt.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Edit Class")
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
                    .disabled(className.isEmpty)
                }
            }
            .onAppear {
                className = classPeriod.name ?? ""
                classSubject = classPeriod.subject ?? ""
            }
        }
    }

    private func saveChanges() {
        classPeriod.name = className
        classPeriod.subject = classSubject.isEmpty ? nil : classSubject

        try? viewContext.save()
        dismiss()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppStateManager())
}
