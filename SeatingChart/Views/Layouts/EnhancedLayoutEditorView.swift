//
//  EnhancedLayoutEditorView.swift
//  SeatingChart
//
//  Created by Claude
//

import SwiftUI
import CoreData

struct EnhancedLayoutEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var classroom: Classroom
    @EnvironmentObject var appStateManager: AppStateManager

    // View state
    @State private var hasUnsavedChanges = false
    @State private var desks: [Desk] = []
    @State private var selectedDeskIDs: Set<UUID> = []
    @State private var viewMode: ViewMode = .edit
    @State private var displayOptions = DisplayOptions.default
    @State private var showingTemplatePicker = false
    @State private var showingDeskTypePicker = false
    @State private var isMultiSelectMode = false
    @State private var alignmentGuides: [AlignmentGuide] = []

    // Undo/Redo
    @State private var undoStack: [[Desk]] = []
    @State private var redoStack: [[Desk]] = []

    // Room settings
    @State private var roomSize = CGSize(width: 1000, height: 800)

    // Gesture state
    @State private var draggedDeskID: UUID?
    @State private var dragStartPosition: CGPoint?

    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            // Main canvas
            ZoomableCanvas {
                ZStack {
                    // Grid overlay
                    if displayOptions.showGrid && viewMode == .edit {
                        GridOverlay(size: roomSize, gridSize: displayOptions.gridSize)
                    }

                    // Room walls with front indicator
                    RoomWallsView(size: roomSize)

                    // Alignment guides
                    ForEach(alignmentGuides) { guide in
                        guide.view
                    }

                    // Desks
                    ForEach(Array(desks.enumerated()), id: \.element.id) { index, desk in
                        DeskShape(
                            desk: desk,
                            students: studentsForDesk(desk),
                            isSelected: selectedDeskIDs.contains(desk.id),
                            showStudents: viewMode != .edit && displayOptions.showStudentPhotos,
                            showNames: displayOptions.showStudentNames,
                            privacyMode: appStateManager.privacyModeEnabled || displayOptions.privacyBlur
                        )
                        .position(desk.position)
                        .onTapGesture {
                            handleDeskTap(desk)
                        }
                        .highPriorityGesture(
                            viewMode == .edit && selectedDeskIDs.contains(desk.id) ?
                            DragGesture(coordinateSpace: .named("canvas"))
                                .onChanged { value in
                                    updateDeskPosition(at: index, to: value.location)
                                }
                                .onEnded { _ in
                                    commitDeskDrag()
                                } : nil
                        )
                        .onLongPressGesture {
                            handleDeskLongPress(desk)
                        }
                    }
                }
                .frame(width: roomSize.width, height: roomSize.height)
                .coordinateSpace(name: "canvas")
            }

            // Floating action button for adding desks
            if viewMode == .edit && !isMultiSelectMode {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingDeskTypePicker = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 56))
                                .foregroundColor(.blue)
                                .background(Circle().fill(Color.white))
                        }
                        .padding(.trailing, 30)
                        .padding(.bottom, 30)
                        .shadow(radius: 4)
                    }
                }
            }
        }
        .navigationTitle(classroom.name ?? "Layout Editor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if viewMode == .edit {
                    editModeButtons
                }

                Menu {
                    displayOptionsMenu
                } label: {
                    Image(systemName: "ellipsis.circle")
                }

                Button("Save") {
                    saveDesks()
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showingTemplatePicker) {
            TemplatePickerView(selectedTemplate: { template in
                applyTemplate(template)
                showingTemplatePicker = false
            })
        }
        .sheet(isPresented: $showingDeskTypePicker) {
            DeskTypePickerView(selectedType: { type in
                addDesk(type: type)
                showingDeskTypePicker = false
            })
        }
        .onAppear {
            loadDesks()
        }
    }

    // MARK: - Subviews

    private var modePicker: some View {
        Menu {
            ForEach(ViewMode.allCases) { mode in
                Button(action: { viewMode = mode }) {
                    Label(mode.displayName, systemImage: mode.icon)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewMode.icon)
                Text(viewMode.displayName)
                    .font(.subheadline)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
        }
    }

    @ViewBuilder
    private var editModeButtons: some View {
        // Undo button
        Button(action: undo) {
            Image(systemName: "arrow.uturn.backward")
        }
        .disabled(undoStack.isEmpty)

        // Redo button
        Button(action: redo) {
            Image(systemName: "arrow.uturn.forward")
        }
        .disabled(redoStack.isEmpty)

        // Multi-select toggle
        Button(action: { isMultiSelectMode.toggle() }) {
            Image(systemName: isMultiSelectMode ? "checkmark.circle.fill" : "checkmark.circle")
        }

        // Template button
        Button(action: { showingTemplatePicker = true }) {
            Image(systemName: "square.grid.3x3")
        }
    }

    @ViewBuilder
    private var displayOptionsMenu: some View {
        Toggle("Show Photos", isOn: $displayOptions.showStudentPhotos)
        Toggle("Show Names", isOn: $displayOptions.showStudentNames)
        Toggle("Privacy Blur", isOn: $displayOptions.privacyBlur)

        if viewMode == .edit {
            Divider()
            Toggle("Show Grid", isOn: $displayOptions.showGrid)
        }

        Divider()
        Button("Clear All Desks", role: .destructive, action: clearAllDesks)
    }

    // MARK: - Gestures

    private func updateDeskPosition(at index: Int, to location: CGPoint) {
        guard index < desks.count else { return }

        // Save undo state on first drag
        if draggedDeskID != desks[index].id {
            saveUndoState()
            draggedDeskID = desks[index].id
        }

        var updatedDesk = desks[index]
        updatedDesk.position = location

        // Snap to grid if enabled
        if displayOptions.showGrid {
            updatedDesk.position = snapToGrid(updatedDesk.position)
        }

        desks[index] = updatedDesk

        // Calculate alignment guides
        updateAlignmentGuides(for: updatedDesk)
    }

    // MARK: - Desk Management

    private func handleDeskTap(_ desk: Desk) {
        if isMultiSelectMode {
            if selectedDeskIDs.contains(desk.id) {
                selectedDeskIDs.remove(desk.id)
            } else {
                selectedDeskIDs.insert(desk.id)
            }
        } else if viewMode == .edit {
            selectedDeskIDs = [desk.id]
        }
    }

    private func handleDeskLongPress(_ desk: Desk) {
        if viewMode == .edit {
            selectedDeskIDs = [desk.id]
            // Show context menu would go here
        }
    }

    private func commitDeskDrag() {
        draggedDeskID = nil
        dragStartPosition = nil
        alignmentGuides = []
    }

    private func snapToGrid(_ point: CGPoint) -> CGPoint {
        let gridSize = displayOptions.gridSize
        return CGPoint(
            x: round(point.x / gridSize) * gridSize,
            y: round(point.y / gridSize) * gridSize
        )
    }

    private func updateAlignmentGuides(for desk: Desk) {
        var guides: [AlignmentGuide] = []
        let threshold: CGFloat = 5

        for otherDesk in desks where otherDesk.id != desk.id {
            // Vertical alignment
            if abs(desk.centerX - otherDesk.centerX) < threshold {
                guides.append(AlignmentGuide(
                    type: .vertical,
                    position: otherDesk.centerX,
                    start: min(desk.centerY, otherDesk.centerY) - 50,
                    end: max(desk.centerY, otherDesk.centerY) + 50
                ))
            }

            // Horizontal alignment
            if abs(desk.centerY - otherDesk.centerY) < threshold {
                guides.append(AlignmentGuide(
                    type: .horizontal,
                    position: otherDesk.centerY,
                    start: min(desk.centerX, otherDesk.centerX) - 50,
                    end: max(desk.centerX, otherDesk.centerX) + 50
                ))
            }
        }

        alignmentGuides = guides
    }

    private func addDesk(type: DeskType) {
        saveUndoState()

        let newDesk = Desk(
            position: CGPoint(x: roomSize.width / 2, y: roomSize.height / 2),
            type: type
        )
        desks.append(newDesk)
        selectedDeskIDs = [newDesk.id]
    }

    private func clearAllDesks() {
        saveUndoState()
        desks.removeAll()
        selectedDeskIDs.removeAll()
    }

    private func applyTemplate(_ template: LayoutTemplate) {
        saveUndoState()
        desks = template.generateDesks(in: roomSize, config: TemplateConfiguration())
        selectedDeskIDs.removeAll()
    }

    // MARK: - Undo/Redo

    private func saveUndoState() {
        undoStack.append(desks)
        if undoStack.count > 50 { // Limit undo history
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }

    private func undo() {
        guard let previousState = undoStack.popLast() else { return }
        redoStack.append(desks)
        desks = previousState
        selectedDeskIDs.removeAll()
    }

    private func redo() {
        guard let nextState = redoStack.popLast() else { return }
        undoStack.append(desks)
        desks = nextState
        selectedDeskIDs.removeAll()
    }

    // MARK: - Data Persistence

    private func loadDesks() {
        // Load desks from classroom.deskPositionsArray if available
        if let data = classroom.deskPositions,
           let loadedDesks = try? JSONDecoder().decode([Desk].self, from: data) {
            desks = loadedDesks
        } else {
            // Show template picker on first load
            showingTemplatePicker = true
        }
    }

    private func saveDesks() {
        // Save desks to classroom.deskPositions
        if let data = try? JSONEncoder().encode(desks) {
            classroom.deskPositions = data
            try? viewContext.save()
        }
    }

    // MARK: - Helpers

    private func studentsForDesk(_ desk: Desk) -> [Student] {
        guard viewMode != .edit else { return [] }

        // Fetch students assigned to this desk from Core Data
        // This would need to be implemented based on your data model
        return []
    }
}

// MARK: - Supporting Views

struct GridOverlay: View {
    let size: CGSize
    let gridSize: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let cols = Int(size.width / gridSize)
            let rows = Int(size.height / gridSize)

            for col in 0...cols {
                let x = CGFloat(col) * gridSize
                for row in 0...rows {
                    let y = CGFloat(row) * gridSize
                    context.fill(
                        Circle().path(in: CGRect(x: x - 1, y: y - 1, width: 2, height: 2)),
                        with: .color(.gray.opacity(0.2))
                    )
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }
}

struct AlignmentGuide: Identifiable {
    let id = UUID()
    let type: AlignmentType
    let position: CGFloat
    let start: CGFloat
    let end: CGFloat

    enum AlignmentType {
        case vertical
        case horizontal
    }

    var view: some View {
        Group {
            if type == .vertical {
                Path { path in
                    path.move(to: CGPoint(x: position, y: start))
                    path.addLine(to: CGPoint(x: position, y: end))
                }
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
            } else {
                Path { path in
                    path.move(to: CGPoint(x: start, y: position))
                    path.addLine(to: CGPoint(x: end, y: position))
                }
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let classroom = Classroom(context: context)
    classroom.id = UUID()
    classroom.name = "Enhanced Layout"
    classroom.rows = 8
    classroom.columns = 10
    classroom.isActive = false

    return NavigationStack {
        EnhancedLayoutEditorView(classroom: classroom)
            .environment(\.managedObjectContext, context)
            .environmentObject(AppStateManager.shared)
    }
}
