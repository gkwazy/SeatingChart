//
//  EnhancedLayoutEditorView.swift
//  SeatingChart
//
//  Redesigned with Apple HIG patterns for editor UI
//  Refactored: Command pattern for memory-efficient undo/redo
//

import SwiftUI
import CoreData

// MARK: - Undo Command (Memory-Efficient Command Pattern)

/// Represents a reversible edit operation storing only the delta
enum UndoCommand {
    case addDesk(Desk)
    case removeDesks([Desk])
    case moveDesk(id: UUID, from: CGPoint, to: CGPoint)
    case replaceAll(oldDesks: [Desk], newDesks: [Desk])

    /// Apply this command (for redo)
    func apply(to desks: inout [Desk]) {
        switch self {
        case .addDesk(let desk):
            desks.append(desk)
        case .removeDesks(let removed):
            let removedIDs = Set(removed.map { $0.id })
            desks.removeAll { removedIDs.contains($0.id) }
        case .moveDesk(let id, _, let to):
            if let index = desks.firstIndex(where: { $0.id == id }) {
                desks[index].position = to
            }
        case .replaceAll(_, let newDesks):
            desks = newDesks
        }
    }

    /// Reverse this command (for undo)
    func reverse(to desks: inout [Desk]) {
        switch self {
        case .addDesk(let desk):
            desks.removeAll { $0.id == desk.id }
        case .removeDesks(let removed):
            desks.append(contentsOf: removed)
        case .moveDesk(let id, let from, _):
            if let index = desks.firstIndex(where: { $0.id == id }) {
                desks[index].position = from
            }
        case .replaceAll(let oldDesks, _):
            desks = oldDesks
        }
    }
}

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
    @State private var showingDiscardAlert = false
    @State private var alignmentGuides: [AlignmentGuide] = []
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""

    // Undo/Redo - Command pattern for memory efficiency
    @State private var undoStack: [UndoCommand] = []
    @State private var redoStack: [UndoCommand] = []
    private let maxUndoHistory = 50

    // Room settings
    @State private var roomSize = CGSize(width: 1000, height: 800)

    // Gesture state for drag tracking
    @State private var draggedDeskID: UUID?
    @State private var dragStartPosition: CGPoint?
    @State private var currentDragPosition: CGPoint?

    // Computed properties
    private var isMultiSelectMode: Bool {
        selectedDeskIDs.count > 1
    }

    var body: some View {
        ZStack {
            // Background
            Theme.Colors.ivory
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

            // Bottom toolbar
            VStack {
                Spacer()
                bottomToolbar
            }
        }
        .navigationTitle(classroom.name ?? "Layout Editor")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Left: Cancel
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    if hasUnsavedChanges {
                        showingDiscardAlert = true
                    } else {
                        dismiss()
                    }
                }
                .foregroundColor(Theme.Colors.slate)
            }

            // Right: Done (saves and exits)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    saveDesks()
                    dismiss()
                }
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.primary)
            }
        }
        .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) { }
        } message: {
            Text("You have unsaved changes to this layout. Are you sure you want to discard them?")
        }
        .alert("Save Failed", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage)
        }
        .sheet(isPresented: $showingTemplatePicker) {
            PresetTemplatePickerView(roomSize: roomSize) { newDesks in
                applyDesks(newDesks)
                hasUnsavedChanges = true
            }
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

    // MARK: - Bottom Toolbar (Apple HIG style)

    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            // Desk count indicator (Issue 1: shows live count)
            HStack {
                Spacer()
                HStack(spacing: Theme.Spacing.xxs) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 12, weight: .medium))
                    Text("\(desks.count) desk\(desks.count == 1 ? "" : "s")")
                        .font(Theme.Typography.caption(12, weight: .semibold))
                }
                .foregroundColor(Theme.Colors.forest)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xxs)
                .background(Theme.Colors.forest.opacity(0.1))
                .cornerRadius(Theme.Radius.full)
                Spacer()
            }
            .padding(.bottom, Theme.Spacing.xs)

            HStack(spacing: 0) {
                // Template picker button
                ToolbarButton(
                    icon: "square.grid.2x2",
                    label: "Templates",
                    action: { showingTemplatePicker = true }
                )

                Spacer()

                // Add desk button
                ToolbarButton(
                    icon: "plus.rectangle",
                    label: "Add Desk",
                    action: { showingDeskTypePicker = true }
                )

                Spacer()

                // Delete desk button (Issue 1: add delete capability)
                ToolbarButton(
                    icon: "trash",
                    label: "Delete",
                    isDisabled: selectedDeskIDs.isEmpty,
                    action: deleteSelectedDesks
                )

                Spacer()

                // Undo button
                ToolbarButton(
                    icon: "arrow.uturn.backward",
                    label: "Undo",
                    isDisabled: undoStack.isEmpty,
                    action: undo
                )

                Spacer()

                // Options menu
                Menu {
                    displayOptionsMenu
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 22))
                        Text("More")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(Theme.Colors.slate)
                    .frame(minWidth: 60)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 8, y: -2)
        )
    }

    @ViewBuilder
    private var displayOptionsMenu: some View {
        Section {
            Toggle("Show Grid", isOn: $displayOptions.showGrid)
            Toggle("Show Photos", isOn: $displayOptions.showStudentPhotos)
            Toggle("Show Names", isOn: $displayOptions.showStudentNames)
        }

        Section {
            if !redoStack.isEmpty {
                Button(action: redo) {
                    Label("Redo", systemImage: "arrow.uturn.forward")
                }
            }
        }

        Section {
            Button(role: .destructive, action: clearAllDesks) {
                Label("Clear All Desks", systemImage: "trash")
            }
        }
    }

    // MARK: - Toolbar Button Component

    private struct ToolbarButton: View {
        let icon: String
        let label: String
        var isDisabled: Bool = false
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                VStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                    Text(label)
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(isDisabled ? Theme.Colors.stone : Theme.Colors.primary)
                .frame(minWidth: 60)
            }
            .disabled(isDisabled)
        }
    }

    // MARK: - Gestures

    private func updateDeskPosition(at index: Int, to location: CGPoint) {
        guard index < desks.count else { return }

        // Record start position on first drag movement
        if draggedDeskID != desks[index].id {
            draggedDeskID = desks[index].id
            dragStartPosition = desks[index].position
        }

        var newPosition = location

        // Snap to grid if enabled
        if displayOptions.showGrid {
            newPosition = snapToGrid(newPosition)
        }

        currentDragPosition = newPosition
        desks[index].position = newPosition

        // Calculate alignment guides
        updateAlignmentGuides(for: desks[index])
        hasUnsavedChanges = true
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
        // Record move command if position actually changed
        if let deskID = draggedDeskID,
           let startPos = dragStartPosition,
           let endPos = currentDragPosition,
           startPos != endPos {
            let command = UndoCommand.moveDesk(id: deskID, from: startPos, to: endPos)
            pushUndoCommand(command)
        }

        draggedDeskID = nil
        dragStartPosition = nil
        currentDragPosition = nil
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
        // Calculate center position snapped to grid
        let centerX = roomSize.width / 2
        let centerY = roomSize.height / 2
        let snappedPosition = snapToGrid(CGPoint(x: centerX, y: centerY))

        let newDesk = Desk(
            position: snappedPosition,
            type: type
        )

        // Record command and apply
        let command = UndoCommand.addDesk(newDesk)
        pushUndoCommand(command)
        desks.append(newDesk)

        selectedDeskIDs = [newDesk.id]
        hasUnsavedChanges = true
    }

    private func clearAllDesks() {
        guard !desks.isEmpty else { return }

        // Record command with all current desks for undo
        let command = UndoCommand.replaceAll(oldDesks: desks, newDesks: [])
        pushUndoCommand(command)

        desks.removeAll()
        selectedDeskIDs.removeAll()
        hasUnsavedChanges = true
    }

    /// Delete selected desks (Issue 1: supports desk deletion with count update)
    private func deleteSelectedDesks() {
        guard !selectedDeskIDs.isEmpty else { return }

        // Capture desks being deleted for undo
        let deletedDesks = desks.filter { selectedDeskIDs.contains($0.id) }
        let command = UndoCommand.removeDesks(deletedDesks)
        pushUndoCommand(command)

        desks.removeAll { selectedDeskIDs.contains($0.id) }
        selectedDeskIDs.removeAll()
        hasUnsavedChanges = true
    }

    private func applyTemplate(_ template: LayoutTemplate) {
        let newDesks = template.generateDesks(in: roomSize, config: TemplateConfiguration(), gridSize: displayOptions.gridSize)

        // Record full replacement for undo
        let command = UndoCommand.replaceAll(oldDesks: desks, newDesks: newDesks)
        pushUndoCommand(command)

        desks = newDesks
        selectedDeskIDs.removeAll()
        hasUnsavedChanges = true
    }

    private func applyDesks(_ newDesks: [Desk]) {
        // Record full replacement for undo
        let command = UndoCommand.replaceAll(oldDesks: desks, newDesks: newDesks)
        pushUndoCommand(command)

        desks = newDesks
        selectedDeskIDs.removeAll()
        hasUnsavedChanges = true
    }

    // MARK: - Undo/Redo (Command Pattern)

    /// Push a command onto the undo stack
    private func pushUndoCommand(_ command: UndoCommand) {
        undoStack.append(command)
        if undoStack.count > maxUndoHistory {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }

    private func undo() {
        guard let command = undoStack.popLast() else { return }
        command.reverse(to: &desks)
        redoStack.append(command)
        selectedDeskIDs.removeAll()
        hasUnsavedChanges = true
    }

    private func redo() {
        guard let command = redoStack.popLast() else { return }
        command.apply(to: &desks)
        undoStack.append(command)
        selectedDeskIDs.removeAll()
        hasUnsavedChanges = true
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
        do {
            let data = try JSONEncoder().encode(desks)
            classroom.deskPositions = data
            try viewContext.save()
        } catch {
            saveErrorMessage = "Could not save layout: \(error.localizedDescription)"
            showingSaveError = true
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
