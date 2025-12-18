//
//  PresetTemplatePickerView.swift
//  SeatingChart
//
//  Created by GKWazy Software
//

import SwiftUI

struct PresetTemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss

    let roomSize: CGSize
    let onSelect: ([Desk]) -> Void

    @State private var selectedTemplate: LayoutTemplate = .traditionalRows
    @State private var config: TemplateConfiguration = TemplateConfiguration()
    @State private var previewDesks: [Desk] = []

    init(roomSize: CGSize = CGSize(width: 1000, height: 800), onSelect: @escaping ([Desk]) -> Void) {
        self.roomSize = roomSize
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Preview Area
                TemplatePreviewCanvas(desks: previewDesks, roomSize: roomSize)
                    .frame(height: 280)
                    .background(Color(.systemGroupedBackground))

                // Template Selection & Configuration
                ScrollView {
                    VStack(spacing: 24) {
                        // Template Grid by Category
                        templateSelectionSection

                        // Configuration Section
                        if selectedTemplate.needsConfiguration {
                            configurationSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Choose Layout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onSelect(previewDesks)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedTemplate == .empty && previewDesks.isEmpty)
                }
            }
            .onAppear {
                config = TemplateConfiguration.smartDefaults(for: selectedTemplate, totalDesks: config.totalDesks)
                updatePreview()
            }
            .onChange(of: selectedTemplate) { _, newTemplate in
                config = TemplateConfiguration.smartDefaults(for: newTemplate, totalDesks: config.totalDesks)
                updatePreview()
            }
            .onChange(of: config) { _, _ in
                updatePreview()
            }
        }
    }

    // MARK: - Template Selection

    private var templateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(LayoutTemplate.categorized, id: \.0) { category, templates in
                VStack(alignment: .leading, spacing: 12) {
                    // Category Header
                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(category.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                    }

                    // Template Pills
                    FlowLayout(spacing: 8) {
                        ForEach(templates) { template in
                            TemplateChip(
                                template: template,
                                isSelected: selectedTemplate == template,
                                action: { selectedTemplate = template }
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Configuration Section

    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Configuration")
                    .font(.headline)
                Spacer()
                Text("\(previewDesks.count) desks")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Total Desks Slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Total Desks")
                    Spacer()
                    Text("\(config.totalDesks)")
                        .foregroundColor(.secondary)
                }
                Slider(value: Binding(
                    get: { Double(config.totalDesks) },
                    set: { config.totalDesks = Int($0) }
                ), in: 4...50, step: 1)
                .tint(.blue)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)

            // Template-specific controls
            templateSpecificControls
        }
    }

    @ViewBuilder
    private var templateSpecificControls: some View {
        switch selectedTemplate {
        case .traditionalRows:
            ConfigRow(title: "Rows", value: $config.rows, range: 2...10)
            ConfigRow(title: "Columns", value: $config.columns, range: 2...8)

        case .pairs:
            ConfigRow(title: "Pair Columns", value: $config.pairColumns, range: 1...6)
            ConfigRow(title: "Rows", value: $config.pairRows, range: 2...10)

        case .groups:
            ConfigRow(title: "Number of Groups", value: $config.numberOfGroups, range: 2...12)
            ConfigRow(title: "Desks per Group", value: $config.desksPerGroup, range: 2...8)

        case .uShape:
            ConfigRow(title: "Back Row Desks", value: $config.uShapeTopCount, range: 3...12)
            ConfigRow(title: "Side Desks (each)", value: $config.uShapeSideCount, range: 2...8)

        case .labStations:
            ConfigRow(title: "Number of Tables", value: $config.numberOfStations, range: 2...12)
            ConfigRow(title: "Seats per Table", value: $config.seatsPerStation, range: 2...8)

        case .choirLoft:
            ConfigRow(title: "Rows", value: $config.choirRows, range: 2...8)
            ConfigRow(title: "Columns", value: $config.choirColumns, range: 4...12)

        case .computerLab:
            ConfigRow(title: "Top Wall Desks", value: $config.perimeterTopCount, range: 2...10)
            ConfigRow(title: "Bottom Wall Desks", value: $config.perimeterBottomCount, range: 2...10)
            ConfigRow(title: "Side Wall Desks", value: $config.perimeterSideCount, range: 2...8)

        case .seminar:
            ConfigRow(title: "Table Length", value: $config.seminarTableLength, range: 4...16)

        case .theater:
            ConfigRow(title: "Rows", value: $config.theaterRows, range: 3...10)
            ConfigRow(title: "Seats per Row", value: $config.theaterColumnsPerRow, range: 4...14)
            ConfigSlider(title: "Curve Amount", value: $config.theaterCurveAmount, range: 0...1)

        case .collaborativePods:
            ConfigRow(title: "Number of Pods", value: $config.podCount, range: 2...8)
            ConfigRow(title: "Desks per Pod", value: $config.desksPerPod, range: 4...8)

        case .empty:
            EmptyView()
        }
    }

    // MARK: - Preview Update

    private func updatePreview() {
        previewDesks = selectedTemplate.generateDesks(in: roomSize, config: config)
    }
}

// MARK: - Supporting Views

struct TemplateChip: View {
    let template: LayoutTemplate
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: template.icon)
                    .font(.system(size: 14))
                Text(template.displayName)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.tertiarySystemGroupedBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ConfigRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Stepper("\(value)", value: $value, in: range)
                .labelsHidden()
            Text("\(value)")
                .frame(width: 30)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct ConfigSlider: View {
    let title: String
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: "%.1f", value))
                    .foregroundColor(.secondary)
            }
            Slider(value: $value, in: range)
                .tint(.blue)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Template Preview Canvas

struct TemplatePreviewCanvas: View {
    let desks: [Desk]
    let roomSize: CGSize

    var body: some View {
        GeometryReader { geometry in
            let scale = min(
                (geometry.size.width - 32) / roomSize.width,
                (geometry.size.height - 32) / roomSize.height
            )

            ZStack {
                // Room outline
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: roomSize.width * scale, height: roomSize.height * scale)

                // Front indicator
                VStack {
                    Text("FRONT")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
                .frame(width: roomSize.width * scale, height: roomSize.height * scale)

                // Desks
                ForEach(desks) { desk in
                    PreviewDeskShape(desk: desk, scale: scale)
                        .position(
                            x: desk.position.x * scale,
                            y: desk.position.y * scale
                        )
                }
            }
            .frame(width: roomSize.width * scale, height: roomSize.height * scale)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}

struct PreviewDeskShape: View {
    let desk: Desk
    let scale: CGFloat

    var body: some View {
        Group {
            switch desk.type {
            case .rectangle, .longRectangle:
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue.opacity(0.7))
                    .frame(
                        width: desk.size.width * scale,
                        height: desk.size.height * scale
                    )
            case .square:
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue.opacity(0.7))
                    .frame(
                        width: desk.size.width * scale,
                        height: desk.size.height * scale
                    )
            case .circle:
                Circle()
                    .fill(Color.green.opacity(0.7))
                    .frame(
                        width: desk.size.width * scale,
                        height: desk.size.height * scale
                    )
            case .trapezoid:
                TrapezoidShape()
                    .fill(Color.orange.opacity(0.7))
                    .frame(
                        width: desk.size.width * scale,
                        height: desk.size.height * scale
                    )
            }
        }
        .rotationEffect(desk.rotation)
    }
}

// TrapezoidShape is defined in DeskShape.swift

// MARK: - Flow Layout for Template Chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                          proposal: ProposedViewSize(result.sizes[index]))
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint], sizes: [CGSize]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            sizes.append(size)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }

        totalHeight = currentY + rowHeight
        return (CGSize(width: totalWidth, height: totalHeight), positions, sizes)
    }
}

#Preview {
    PresetTemplatePickerView { desks in
        // Preview callback
    }
}
