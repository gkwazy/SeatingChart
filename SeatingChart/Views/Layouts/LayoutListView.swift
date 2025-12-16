//
//  LayoutListView.swift
//  SeatingChart
//
//  Created on 2025-11-29.
//

import SwiftUI
import CoreData

struct LayoutListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var classPeriod: ClassPeriod

    @State private var showingCreateFlow = false

    var layouts: [Classroom] {
        let layoutSet = classPeriod.classrooms as? Set<Classroom> ?? []
        return layoutSet.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    var body: some View {
        List {
            ForEach(layouts) { layout in
                NavigationLink(destination: EnhancedLayoutEditorView(classroom: layout)) {
                    LayoutRow(layout: layout)
                }
            }
            .onDelete(perform: deleteLayouts)
        }
        .navigationTitle("Classroom Layouts")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCreateFlow = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .fullScreenCover(isPresented: $showingCreateFlow) {
            CreateLayoutFlowView(classPeriod: classPeriod, isPresented: $showingCreateFlow)
        }
        .overlay {
            if layouts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "square.grid.3x3")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)

                    Text("No Layouts Yet")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Create a classroom layout to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button(action: { showingCreateFlow = true }) {
                        Label("Create Layout", systemImage: "plus.circle.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }
            }
        }
    }

    private func deleteLayouts(offsets: IndexSet) {
        withAnimation {
            offsets.map { layouts[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                print("Error deleting layout: \(error.localizedDescription)")
            }
        }
    }
}

struct LayoutRow: View {
    let layout: Classroom

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(layout.name ?? "Unnamed Layout")
                .font(.headline)

            HStack {
                if let deskData = layout.deskPositions,
                   let deskCount = try? JSONDecoder().decode([Desk].self, from: deskData).count {
                    Text("\(deskCount) desks")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(layout.rows) rows x \(layout.columns) columns")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if layout.isActive {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Active")
                    }
                    .font(.caption)
                    .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create Layout Flow

enum CreateLayoutStep {
    case name
    case template
    case configuration
}

struct CreateLayoutFlowView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var classPeriod: ClassPeriod
    @Binding var isPresented: Bool

    @State private var currentStep: CreateLayoutStep = .name
    @State private var layoutName = ""
    @State private var selectedTemplate: LayoutTemplate?
    @State private var config = TemplateConfiguration()
    @State private var navigateToEditor = false
    @State private var createdClassroom: Classroom?

    var body: some View {
        NavigationStack {
            Group {
                switch currentStep {
                case .name:
                    nameStepView
                case .template:
                    templateStepView
                case .configuration:
                    configurationStepView
                }
            }
            .navigationDestination(isPresented: $navigateToEditor) {
                if let classroom = createdClassroom {
                    EnhancedLayoutEditorView(classroom: classroom)
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Done") {
                                    isPresented = false
                                }
                            }
                        }
                }
            }
        }
    }

    // MARK: - Step 1: Name

    private var nameStepView: some View {
        Form {
            Section(header: Text("Layout Name")) {
                TextField("Enter a name (e.g., Main Room)", text: $layoutName)
                    .textInputAutocapitalization(.words)
            }

            Section {
                Text("Give your layout a descriptive name to easily identify it later.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("New Layout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    isPresented = false
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Next") {
                    currentStep = .template
                }
                .disabled(layoutName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    // MARK: - Step 2: Template Selection

    private var templateStepView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                ForEach(LayoutTemplate.allCases) { template in
                    TemplateCard(template: template, isSelected: selectedTemplate == template, action: {
                        selectedTemplate = template
                    })
                }
            }
            .padding()
        }
        .navigationTitle("Choose Template")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    currentStep = .name
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Next") {
                    if let template = selectedTemplate {
                        if template.needsConfiguration {
                            setDefaultsForTemplate(template)
                            currentStep = .configuration
                        } else {
                            createLayoutAndNavigate()
                        }
                    }
                }
                .disabled(selectedTemplate == nil)
            }
        }
    }

    // MARK: - Step 3: Configuration

    private var configurationStepView: some View {
        Form {
            // Total desks - "the law"
            Section(header: Text("Total Desks")) {
                Stepper("Number of Desks: \(config.totalDesks)", value: $config.totalDesks, in: 1...100)
                Text("This is the maximum number of desks that will be created")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Template-specific configuration
            if let template = selectedTemplate {
                templateConfigSection(for: template)

                // Preview section
                Section(header: Text("Preview")) {
                    previewInfo(for: template)
                }
            }
        }
        .navigationTitle("Configure Layout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    currentStep = .template
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Create") {
                    createLayoutAndNavigate()
                }
                .fontWeight(.semibold)
            }
        }
    }

    @ViewBuilder
    private func templateConfigSection(for template: LayoutTemplate) -> some View {
        switch template {
        case .traditionalRows:
            Section(header: Text("Grid Layout")) {
                Stepper("Rows: \(config.rows)", value: $config.rows, in: 1...15)
                Stepper("Columns: \(config.columns)", value: $config.columns, in: 1...15)
                Text("Grid capacity: \(config.rows * config.columns) desks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .pairs:
            Section(header: Text("Pairs Layout")) {
                Stepper("Pair Columns: \(config.pairColumns)", value: $config.pairColumns, in: 1...10)
                Stepper("Rows of Pairs: \(config.pairRows)", value: $config.pairRows, in: 1...10)
                Text("Capacity: \(config.pairColumns * config.pairRows * 2) desks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .groups:
            Section(header: Text("Group Layout")) {
                Stepper("Number of Groups: \(config.numberOfGroups)", value: $config.numberOfGroups, in: 1...20)
                Stepper("Desks per Group: \(config.desksPerGroup)", value: $config.desksPerGroup, in: 2...8)
                Text("Capacity: \(config.numberOfGroups * config.desksPerGroup) desks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .uShape:
            Section(header: Text("U-Shape Layout")) {
                Stepper("Top Seats: \(config.uShapeTopCount)", value: $config.uShapeTopCount, in: 3...15)
                Stepper("Side Seats (each): \(config.uShapeSideCount)", value: $config.uShapeSideCount, in: 1...10)
                Text("Capacity: \(config.uShapeTotalSeats) desks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .labStations:
            Section(header: Text("Lab Stations")) {
                Stepper("Number of Stations: \(config.numberOfStations)", value: $config.numberOfStations, in: 1...12)
                Stepper("Seats per Station: \(config.seatsPerStation)", value: $config.seatsPerStation, in: 2...8)
                Text("Each station is a round table")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .choirLoft:
            Section(header: Text("Choir Loft Layout")) {
                Stepper("Rows: \(config.choirRows)", value: $config.choirRows, in: 2...10)
                Stepper("Columns: \(config.choirColumns)", value: $config.choirColumns, in: 3...15)
                Text("Seats are staggered in alternating rows")
                    .font(.caption)
                    .foregroundColor(.blue)
            }

        case .empty:
            Section {
                Text("Empty room - you'll add desks manually")
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func previewInfo(for template: LayoutTemplate) -> some View {
        let capacity = templateCapacity(for: template)
        let actualCount = min(capacity, config.totalDesks)

        HStack {
            Image(systemName: template.icon)
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text("Will create \(actualCount) desks")
                    .font(.headline)

                if actualCount < config.totalDesks {
                    Text("Template capacity is \(capacity)")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Matches your requested total")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func templateCapacity(for template: LayoutTemplate) -> Int {
        switch template {
        case .traditionalRows:
            return config.rows * config.columns
        case .pairs:
            return config.pairColumns * config.pairRows * 2
        case .groups:
            return config.numberOfGroups * config.desksPerGroup
        case .uShape:
            return config.uShapeTotalSeats
        case .labStations:
            return config.numberOfStations
        case .choirLoft:
            var total = 0
            for row in 0..<config.choirRows {
                total += row % 2 == 1 ? config.choirColumns - 1 : config.choirColumns
            }
            return total
        case .empty:
            return 0
        }
    }

    private func setDefaultsForTemplate(_ template: LayoutTemplate) {
        switch template {
        case .traditionalRows:
            config.rows = 5
            config.columns = 6
            config.totalDesks = 30
        case .pairs:
            config.pairColumns = 4
            config.pairRows = 5
            config.totalDesks = 40
        case .groups:
            config.numberOfGroups = 6
            config.desksPerGroup = 4
            config.totalDesks = 24
        case .uShape:
            config.uShapeTopCount = 7
            config.uShapeSideCount = 4
            config.totalDesks = 15
        case .labStations:
            config.numberOfStations = 6
            config.seatsPerStation = 4
            config.totalDesks = 6
        case .choirLoft:
            config.choirRows = 4
            config.choirColumns = 8
            config.totalDesks = 30
        case .empty:
            config.totalDesks = 0
        }
    }

    private func createLayoutAndNavigate() {
        guard let template = selectedTemplate else { return }

        let classroom = Classroom(context: viewContext)
        classroom.id = UUID()
        classroom.name = layoutName.trimmingCharacters(in: .whitespaces)
        classroom.rows = Int16(config.rows)
        classroom.columns = Int16(config.columns)
        classroom.isActive = false
        classroom.createdAt = Date()

        // Generate desks from template
        let roomSize = CGSize(width: 1000, height: 800)
        let desks = template.generateDesks(in: roomSize, config: config)

        if let desksData = try? JSONEncoder().encode(desks) {
            classroom.deskPositions = desksData
        }

        // Add to the class period
        classPeriod.addToClassrooms(classroom)

        do {
            try viewContext.save()
            createdClassroom = classroom
            navigateToEditor = true
        } catch {
            print("Error saving layout: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let classPeriod = ClassPeriod(context: context)
    classPeriod.id = UUID()
    classPeriod.name = "Period 1"

    return NavigationStack {
        LayoutListView(classPeriod: classPeriod)
            .environment(\.managedObjectContext, context)
    }
}
