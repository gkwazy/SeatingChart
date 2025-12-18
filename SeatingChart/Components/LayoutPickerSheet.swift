//
//  LayoutPickerSheet.swift
//  SeatingChart
//
//  Extracted from MainSeatingChartView for reusability
//  Sheet for selecting and managing classroom layouts
//

import SwiftUI
import CoreData

// MARK: - Layout Picker Sheet

struct LayoutPickerSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var classPeriod: ClassPeriod
    let currentLayout: Classroom?
    let onSelectLayout: (Classroom) -> Void
    let onEditLayout: () -> Void

    @State private var showingCreateFlow = false
    @State private var showingEditFlow = false
    @State private var showingDeleteConfirmation = false
    @State private var layoutToDelete: Classroom?

    var layouts: [Classroom] {
        let classrooms = classPeriod.classrooms as? Set<Classroom> ?? []
        return classrooms.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.ivory
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        layoutsSection
                        actionsSection
                    }
                }
            }
            .navigationTitle("Layouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.forest)
                }
            }
            .fullScreenCover(isPresented: $showingCreateFlow) {
                CreateLayoutFlowView(classPeriod: classPeriod, isPresented: $showingCreateFlow)
            }
            .fullScreenCover(isPresented: $showingEditFlow) {
                if let layout = currentLayout {
                    EditLayoutFlowView(classroom: layout, isPresented: $showingEditFlow)
                }
            }
            .alert("Delete Layout?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let layout = layoutToDelete {
                        deleteLayout(layout)
                    }
                }
            } message: {
                Text("This will permanently delete the layout and cannot be undone.")
            }
        }
    }

    // MARK: - Layouts Section

    private var layoutsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ThemeSectionHeader("Saved Layouts")
                .padding(.horizontal, Theme.Spacing.md)

            if layouts.isEmpty {
                emptyLayoutsView
            } else {
                ForEach(layouts, id: \.id) { layout in
                    layoutRow(layout)
                }
            }
        }
        .padding(.top, Theme.Spacing.md)
    }

    private var emptyLayoutsView: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "square.grid.3x3.slash")
                .font(.system(size: 32))
                .foregroundColor(Theme.Colors.stone)
            Text("No layouts yet")
                .font(Theme.Typography.body(14))
                .foregroundColor(Theme.Colors.slate)
            Text("Create your first layout to get started")
                .font(Theme.Typography.caption(12))
                .foregroundColor(Theme.Colors.stone)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
    }

    private func layoutRow(_ layout: Classroom) -> some View {
        Button {
            onSelectLayout(layout)
            dismiss()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                layoutIcon

                VStack(alignment: .leading, spacing: 2) {
                    Text(layout.name ?? "Unnamed Layout")
                        .font(Theme.Typography.headline(15))
                        .foregroundColor(Theme.Colors.charcoal)

                    if let deskData = layout.deskPositions,
                       let deskCount = try? JSONDecoder().decode([Desk].self, from: deskData).count {
                        Text("\(deskCount) desks")
                            .font(Theme.Typography.caption(12))
                            .foregroundColor(Theme.Colors.slate)
                    }
                }

                Spacer()

                if layout == currentLayout {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.Colors.success)
                }

                // Delete button (only for non-current layouts)
                if layout != currentLayout && layouts.count > 1 {
                    Button {
                        layoutToDelete = layout
                        showingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.Colors.danger.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.Spacing.sm)
            .background(Color.white)
            .cornerRadius(Theme.Radius.sm)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Spacing.md)
        .accessibilityLabel("\(layout.name ?? "Layout"), \(layout == currentLayout ? "currently selected" : "tap to select")")
    }

    private var layoutIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Theme.Colors.forest.opacity(0.1))
                .frame(width: 40, height: 40)

            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.Colors.forest)
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Button {
                showingCreateFlow = true
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                    Text("Create New Layout")
                        .font(Theme.Typography.headline(15, weight: .medium))
                    Spacer()
                }
                .foregroundColor(Theme.Colors.forest)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.forest.opacity(0.08))
                .cornerRadius(Theme.Radius.sm)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Create new layout")

            if currentLayout != nil {
                Button {
                    showingEditFlow = true
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .medium))
                        Text("Edit Current Layout")
                            .font(Theme.Typography.headline(15, weight: .medium))
                        Spacer()
                    }
                    .foregroundColor(Theme.Colors.amber)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.amberLight)
                    .cornerRadius(Theme.Radius.sm)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit current layout")
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Actions

    private func deleteLayout(_ layout: Classroom) {
        viewContext.delete(layout)
        do {
            try viewContext.save()
        } catch {
            #if DEBUG
            print("Failed to delete layout: \(error)")
            #endif
        }
        layoutToDelete = nil
    }
}

#Preview("Layout Picker Sheet") {
    let context = PersistenceController.preview.container.viewContext
    let classPeriod = ClassPeriod(context: context)
    classPeriod.id = UUID()
    classPeriod.name = "Test Class"

    return LayoutPickerSheet(
        classPeriod: classPeriod,
        currentLayout: nil,
        onSelectLayout: { _ in },
        onEditLayout: {}
    )
    .environment(\.managedObjectContext, context)
}
