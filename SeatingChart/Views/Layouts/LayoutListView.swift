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
                #if DEBUG
                print("Error deleting layout: \(error.localizedDescription)")
                #endif
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
            // Issue 2: Removed duplicate Done button - EnhancedLayoutEditorView has its own toolbar
            .navigationDestination(isPresented: $navigateToEditor) {
                if let classroom = createdClassroom {
                    EnhancedLayoutEditorView(classroom: classroom)
                        .onDisappear {
                            // Auto-close the flow when editor is dismissed
                            isPresented = false
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
                NumberInputStepper(label: "Number of Desks", value: $config.totalDesks, range: 1...500)
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
                NumberInputStepper(label: "Rows", value: $config.rows, range: 1...50)
                NumberInputStepper(label: "Columns", value: $config.columns, range: 1...50)
                Text("Grid capacity: \(config.rows * config.columns) desks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .pairs:
            Section(header: Text("Pairs Layout")) {
                NumberInputStepper(label: "Pair Columns", value: $config.pairColumns, range: 1...25)
                NumberInputStepper(label: "Rows of Pairs", value: $config.pairRows, range: 1...25)
                Text("Capacity: \(config.pairColumns * config.pairRows * 2) desks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .groups:
            Section(header: Text("Group Layout")) {
                NumberInputStepper(label: "Number of Groups", value: $config.numberOfGroups, range: 1...100)
                NumberInputStepper(label: "Desks per Group", value: $config.desksPerGroup, range: 2...20)
                Text("Capacity: \(config.numberOfGroups * config.desksPerGroup) desks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .uShape:
            Section(header: Text("U-Shape Layout")) {
                NumberInputStepper(label: "Top Seats", value: $config.uShapeTopCount, range: 1...50)
                NumberInputStepper(label: "Side Seats (each)", value: $config.uShapeSideCount, range: 1...50)
                Text("Capacity: \(config.uShapeTotalSeats) desks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .labStations:
            Section(header: Text("Lab Stations")) {
                NumberInputStepper(label: "Number of Stations", value: $config.numberOfStations, range: 1...100)
                NumberInputStepper(label: "Seats per Station", value: $config.seatsPerStation, range: 2...20)
                Text("Each station is a round table")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .choirLoft:
            Section(header: Text("Choir Loft Layout")) {
                NumberInputStepper(label: "Rows", value: $config.choirRows, range: 1...50)
                NumberInputStepper(label: "Columns", value: $config.choirColumns, range: 1...50)
                Text("Seats are staggered in alternating rows")
                    .font(.caption)
                    .foregroundColor(.blue)
            }

        case .computerLab:
            Section(header: Text("Computer Lab (Perimeter)")) {
                NumberInputStepper(label: "Top Wall Desks", value: $config.perimeterTopCount, range: 1...15)
                NumberInputStepper(label: "Bottom Wall Desks", value: $config.perimeterBottomCount, range: 1...15)
                NumberInputStepper(label: "Side Wall Desks (each)", value: $config.perimeterSideCount, range: 1...10)
                Text("Capacity: \(config.perimeterTotalSeats) desks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .seminar:
            Section(header: Text("Seminar Table")) {
                NumberInputStepper(label: "Table Length", value: $config.seminarTableLength, range: 4...20)
                Text("Long tables arranged for discussion")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .theater:
            Section(header: Text("Theater Style")) {
                NumberInputStepper(label: "Rows", value: $config.theaterRows, range: 2...12)
                NumberInputStepper(label: "Seats per Row", value: $config.theaterColumnsPerRow, range: 4...16)
                Text("Curved rows like a theater")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .collaborativePods:
            Section(header: Text("Collaborative Pods")) {
                NumberInputStepper(label: "Number of Pods", value: $config.podCount, range: 2...10)
                NumberInputStepper(label: "Desks per Pod", value: $config.desksPerPod, range: 4...8)
                Text("Circular clusters for group work")
                    .font(.caption)
                    .foregroundColor(.secondary)
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

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: template.icon)
                    .font(.title)
                    .foregroundColor(.blue)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Template capacity: \(capacity) desks")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Will create: \(actualCount) desks")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }

            if capacity < config.totalDesks {
                Text("Template can only fit \(capacity) of your \(config.totalDesks) requested desks")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else if capacity > config.totalDesks {
                Text("Limited to \(config.totalDesks) desks (template could fit \(capacity))")
                    .font(.caption)
                    .foregroundColor(.blue)
            } else {
                Text("Perfect match!")
                    .font(.caption)
                    .foregroundColor(.green)
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
        case .computerLab:
            return config.perimeterTotalSeats
        case .seminar:
            return config.seminarTableLength
        case .theater:
            return config.theaterRows * config.theaterColumnsPerRow
        case .collaborativePods:
            return config.podCount * config.desksPerPod
        case .empty:
            return 0
        }
    }

    private func setDefaultsForTemplate(_ template: LayoutTemplate) {
        // Only set template-specific defaults, NOT totalDesks
        // User controls totalDesks - it's "the law"
        switch template {
        case .traditionalRows:
            config.rows = 5
            config.columns = 6
        case .pairs:
            config.pairColumns = 4
            config.pairRows = 5
        case .groups:
            config.numberOfGroups = 6
            config.desksPerGroup = 4
        case .uShape:
            config.uShapeTopCount = 7
            config.uShapeSideCount = 4
        case .labStations:
            config.numberOfStations = 6
            config.seatsPerStation = 4
        case .choirLoft:
            config.choirRows = 4
            config.choirColumns = 8
        case .computerLab:
            config.perimeterTopCount = 6
            config.perimeterBottomCount = 6
            config.perimeterSideCount = 4
        case .seminar:
            config.seminarTableLength = 8
        case .theater:
            config.theaterRows = 5
            config.theaterColumnsPerRow = 8
        case .collaborativePods:
            config.podCount = 4
            config.desksPerPod = 6
        case .empty:
            break
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
            #if DEBUG
            print("Error saving layout: \(error.localizedDescription)")
            #endif
        }
    }
}

// MARK: - Edit Layout Flow

enum EditLayoutStep {
    case name
    case options
    case template
    case configuration
}

struct EditLayoutFlowView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var classroom: Classroom
    @Binding var isPresented: Bool

    @State private var currentStep: EditLayoutStep = .name
    @State private var layoutName = ""
    @State private var selectedTemplate: LayoutTemplate?
    @State private var config = TemplateConfiguration()
    @State private var navigateToEditor = false
    @State private var applyNewTemplate = false

    var body: some View {
        NavigationStack {
            Group {
                switch currentStep {
                case .name:
                    nameStepView
                case .options:
                    optionsStepView
                case .template:
                    templateStepView
                case .configuration:
                    configurationStepView
                }
            }
            // Issue 2: Removed duplicate Done button - EnhancedLayoutEditorView has its own toolbar
            .navigationDestination(isPresented: $navigateToEditor) {
                EnhancedLayoutEditorView(classroom: classroom)
                    .onDisappear {
                        // Auto-close the flow when editor is dismissed
                        isPresented = false
                    }
            }
        }
        .onAppear {
            layoutName = classroom.name ?? ""
        }
    }

    // MARK: - Step 1: Name

    private var nameStepView: some View {
        Form {
            Section(header: Text("Layout Name")) {
                TextField("Enter a name", text: $layoutName)
                    .textInputAutocapitalization(.words)
            }

            Section {
                Text("You can rename your layout here.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Edit Layout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    isPresented = false
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Next") {
                    saveNameAndContinue()
                    currentStep = .options
                }
                .disabled(layoutName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    // MARK: - Step 2: Options

    private var optionsStepView: some View {
        Form {
            Section(header: Text("What would you like to do?")) {
                Button {
                    applyNewTemplate = true
                    currentStep = .template
                } label: {
                    HStack {
                        Image(systemName: "square.grid.2x2")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Apply New Template")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Replace current desks with a new layout")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                Button {
                    applyNewTemplate = false
                    navigateToEditor = true
                } label: {
                    HStack {
                        Image(systemName: "pencil.and.outline")
                            .font(.title2)
                            .foregroundColor(.green)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Edit Current Layout")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Manually adjust desk positions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }

            if let deskData = classroom.deskPositions,
               let deskCount = try? JSONDecoder().decode([Desk].self, from: deskData).count {
                Section(header: Text("Current Layout")) {
                    HStack {
                        Image(systemName: "square.grid.3x3")
                            .foregroundColor(.blue)
                        Text("\(deskCount) desks")
                    }
                }
            }
        }
        .navigationTitle("Edit Options")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    currentStep = .name
                }
            }
        }
    }

    // MARK: - Step 3: Template Selection

    private var templateStepView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                ForEach(LayoutTemplate.allCases) { template in
                    TemplateCard(template: template, isSelected: selectedTemplate == template) {
                        selectedTemplate = template
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Choose Template")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    currentStep = .options
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Next") {
                    if let template = selectedTemplate {
                        if template.needsConfiguration {
                            setDefaultsForTemplate(template)
                            currentStep = .configuration
                        } else {
                            applyTemplateAndNavigate()
                        }
                    }
                }
                .disabled(selectedTemplate == nil)
            }
        }
    }

    // MARK: - Step 4: Configuration

    private var configurationStepView: some View {
        Form {
            Section(header: Text("Total Desks")) {
                NumberInputStepper(label: "Number of Desks", value: $config.totalDesks, range: 1...500)
                Text("This is the maximum number of desks that will be created")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let template = selectedTemplate {
                templateConfigSection(for: template)

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
                Button("Apply") {
                    applyTemplateAndNavigate()
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
                NumberInputStepper(label: "Rows", value: $config.rows, range: 1...50)
                NumberInputStepper(label: "Columns", value: $config.columns, range: 1...50)
            }

        case .pairs:
            Section(header: Text("Pairs Layout")) {
                NumberInputStepper(label: "Pair Columns", value: $config.pairColumns, range: 1...25)
                NumberInputStepper(label: "Rows of Pairs", value: $config.pairRows, range: 1...25)
            }

        case .groups:
            Section(header: Text("Group Layout")) {
                NumberInputStepper(label: "Number of Groups", value: $config.numberOfGroups, range: 1...100)
                NumberInputStepper(label: "Desks per Group", value: $config.desksPerGroup, range: 2...20)
            }

        case .uShape:
            Section(header: Text("U-Shape Layout")) {
                NumberInputStepper(label: "Top Seats", value: $config.uShapeTopCount, range: 1...50)
                NumberInputStepper(label: "Side Seats (each)", value: $config.uShapeSideCount, range: 1...50)
            }

        case .labStations:
            Section(header: Text("Lab Stations")) {
                NumberInputStepper(label: "Number of Stations", value: $config.numberOfStations, range: 1...100)
                NumberInputStepper(label: "Seats per Station", value: $config.seatsPerStation, range: 2...20)
            }

        case .choirLoft:
            Section(header: Text("Choir Loft Layout")) {
                NumberInputStepper(label: "Rows", value: $config.choirRows, range: 1...50)
                NumberInputStepper(label: "Columns", value: $config.choirColumns, range: 1...50)
            }

        case .computerLab:
            Section(header: Text("Computer Lab (Perimeter)")) {
                NumberInputStepper(label: "Top Wall Desks", value: $config.perimeterTopCount, range: 1...15)
                NumberInputStepper(label: "Bottom Wall Desks", value: $config.perimeterBottomCount, range: 1...15)
                NumberInputStepper(label: "Side Wall Desks (each)", value: $config.perimeterSideCount, range: 1...10)
            }

        case .seminar:
            Section(header: Text("Seminar Table")) {
                NumberInputStepper(label: "Table Length", value: $config.seminarTableLength, range: 4...20)
            }

        case .theater:
            Section(header: Text("Theater Style")) {
                NumberInputStepper(label: "Rows", value: $config.theaterRows, range: 2...12)
                NumberInputStepper(label: "Seats per Row", value: $config.theaterColumnsPerRow, range: 4...16)
            }

        case .collaborativePods:
            Section(header: Text("Collaborative Pods")) {
                NumberInputStepper(label: "Number of Pods", value: $config.podCount, range: 2...10)
                NumberInputStepper(label: "Desks per Pod", value: $config.desksPerPod, range: 4...8)
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

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: template.icon)
                    .font(.title)
                    .foregroundColor(.blue)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Template capacity: \(capacity) desks")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Will create: \(actualCount) desks")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }

            if capacity < config.totalDesks {
                Text("Template can only fit \(capacity) of your \(config.totalDesks) requested desks")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else if capacity > config.totalDesks {
                Text("Limited to \(config.totalDesks) desks (template could fit \(capacity))")
                    .font(.caption)
                    .foregroundColor(.blue)
            } else {
                Text("Perfect match!")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }

    private func templateCapacity(for template: LayoutTemplate) -> Int {
        switch template {
        case .traditionalRows: return config.rows * config.columns
        case .pairs: return config.pairColumns * config.pairRows * 2
        case .groups: return config.numberOfGroups * config.desksPerGroup
        case .uShape: return config.uShapeTotalSeats
        case .labStations: return config.numberOfStations
        case .choirLoft:
            var total = 0
            for row in 0..<config.choirRows {
                total += row % 2 == 1 ? config.choirColumns - 1 : config.choirColumns
            }
            return total
        case .computerLab: return config.perimeterTotalSeats
        case .seminar: return config.seminarTableLength
        case .theater: return config.theaterRows * config.theaterColumnsPerRow
        case .collaborativePods: return config.podCount * config.desksPerPod
        case .empty: return 0
        }
    }

    private func setDefaultsForTemplate(_ template: LayoutTemplate) {
        // Only set template-specific defaults, NOT totalDesks
        // User controls totalDesks - it's "the law"
        switch template {
        case .traditionalRows:
            config.rows = 5
            config.columns = 6
        case .pairs:
            config.pairColumns = 4
            config.pairRows = 5
        case .groups:
            config.numberOfGroups = 6
            config.desksPerGroup = 4
        case .uShape:
            config.uShapeTopCount = 7
            config.uShapeSideCount = 4
        case .labStations:
            config.numberOfStations = 6
            config.seatsPerStation = 4
        case .choirLoft:
            config.choirRows = 4
            config.choirColumns = 8
        case .computerLab:
            config.perimeterTopCount = 6
            config.perimeterBottomCount = 6
            config.perimeterSideCount = 4
        case .seminar:
            config.seminarTableLength = 8
        case .theater:
            config.theaterRows = 5
            config.theaterColumnsPerRow = 8
        case .collaborativePods:
            config.podCount = 4
            config.desksPerPod = 6
        case .empty:
            break
        }
    }

    private func saveNameAndContinue() {
        classroom.name = layoutName.trimmingCharacters(in: .whitespaces)
        try? viewContext.save()
    }

    private func applyTemplateAndNavigate() {
        guard let template = selectedTemplate else { return }

        // Generate new desks from template
        let roomSize = CGSize(width: 1000, height: 800)
        let desks = template.generateDesks(in: roomSize, config: config)

        if let desksData = try? JSONEncoder().encode(desks) {
            classroom.deskPositions = desksData
        }

        classroom.rows = Int16(config.rows)
        classroom.columns = Int16(config.columns)

        do {
            try viewContext.save()
            navigateToEditor = true
        } catch {
            #if DEBUG
            print("Error saving layout: \(error.localizedDescription)")
            #endif
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
