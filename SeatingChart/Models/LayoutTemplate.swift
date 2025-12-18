//
//  LayoutTemplate.swift
//  SeatingChart
//
//  Created by GKWazy Software
//

import Foundation
import SwiftUI

// Configuration struct for layout-specific parameters
// totalDesks is "the law" - templates will never exceed this number
struct TemplateConfiguration: Equatable {
    var totalDesks: Int = 20

    // Traditional Rows
    var rows: Int = 5
    var columns: Int = 4

    // Pairs
    var pairColumns: Int = 4
    var pairRows: Int = 5

    // Groups
    var numberOfGroups: Int = 5
    var desksPerGroup: Int = 4

    // U-Shape
    var uShapeTopCount: Int = 7
    var uShapeSideCount: Int = 5

    // Lab Stations
    var numberOfStations: Int = 6
    var seatsPerStation: Int = 4

    // Choir Loft
    var choirRows: Int = 4
    var choirColumns: Int = 8

    // Computer Lab (perimeter)
    var perimeterTopCount: Int = 6
    var perimeterBottomCount: Int = 6
    var perimeterSideCount: Int = 4

    // Seminar Table
    var seminarTableLength: Int = 8

    // Theater/Stadium
    var theaterRows: Int = 5
    var theaterColumnsPerRow: Int = 8
    var theaterCurveAmount: CGFloat = 0.3

    // Collaborative Pods
    var podCount: Int = 4
    var desksPerPod: Int = 6

    var uShapeTotalSeats: Int {
        uShapeTopCount + (2 * uShapeSideCount)
    }

    var perimeterTotalSeats: Int {
        perimeterTopCount + perimeterBottomCount + (2 * perimeterSideCount)
    }

    // Smart defaults based on total desk count
    static func smartDefaults(for template: LayoutTemplate, totalDesks: Int) -> TemplateConfiguration {
        var config = TemplateConfiguration()
        config.totalDesks = totalDesks

        switch template {
        case .traditionalRows:
            let cols = min(6, max(3, Int(ceil(sqrt(Double(totalDesks))))))
            config.columns = cols
            config.rows = Int(ceil(Double(totalDesks) / Double(cols)))
        case .pairs:
            config.pairColumns = min(4, max(2, totalDesks / 8))
            config.pairRows = Int(ceil(Double(totalDesks) / Double(config.pairColumns * 2)))
        case .groups:
            config.desksPerGroup = min(6, max(4, totalDesks / 5))
            config.numberOfGroups = Int(ceil(Double(totalDesks) / Double(config.desksPerGroup)))
        case .uShape:
            let total = totalDesks
            config.uShapeTopCount = max(3, total / 3)
            config.uShapeSideCount = max(2, (total - config.uShapeTopCount) / 2)
        case .labStations:
            config.seatsPerStation = min(6, max(2, 4))
            config.numberOfStations = Int(ceil(Double(totalDesks) / Double(config.seatsPerStation)))
        case .choirLoft:
            config.choirColumns = min(10, max(5, Int(ceil(sqrt(Double(totalDesks) * 2)))))
            config.choirRows = Int(ceil(Double(totalDesks) / Double(config.choirColumns)))
        case .computerLab:
            let perSide = totalDesks / 4
            config.perimeterTopCount = perSide
            config.perimeterBottomCount = perSide
            config.perimeterSideCount = max(2, (totalDesks - perSide * 2) / 2)
        case .seminar:
            config.seminarTableLength = max(4, totalDesks / 2)
        case .theater:
            config.theaterColumnsPerRow = min(12, max(5, Int(ceil(sqrt(Double(totalDesks) * 1.5)))))
            config.theaterRows = Int(ceil(Double(totalDesks) / Double(config.theaterColumnsPerRow)))
        case .collaborativePods:
            config.desksPerPod = min(8, max(4, 6))
            config.podCount = Int(ceil(Double(totalDesks) / Double(config.desksPerPod)))
        case .empty:
            break
        }

        return config
    }
}

enum LayoutTemplate: String, CaseIterable, Identifiable {
    case traditionalRows
    case pairs
    case groups
    case uShape
    case labStations
    case choirLoft
    case computerLab
    case seminar
    case theater
    case collaborativePods
    case empty

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .traditionalRows: return "Traditional Rows"
        case .pairs: return "Pairs"
        case .groups: return "Groups"
        case .uShape: return "U-Shape"
        case .labStations: return "Lab Stations"
        case .choirLoft: return "Choir Loft"
        case .computerLab: return "Computer Lab"
        case .seminar: return "Seminar Table"
        case .theater: return "Theater Style"
        case .collaborativePods: return "Collaborative Pods"
        case .empty: return "Empty Room"
        }
    }

    var icon: String {
        switch self {
        case .traditionalRows: return "rectangle.grid.3x2"
        case .pairs: return "rectangle.split.2x1"
        case .groups: return "square.grid.2x2"
        case .uShape: return "u.circle"
        case .labStations: return "circle.grid.3x3"
        case .choirLoft: return "music.note.list"
        case .computerLab: return "desktopcomputer"
        case .seminar: return "rectangle.portrait.arrowtriangle.2.inward"
        case .theater: return "theatermasks"
        case .collaborativePods: return "circle.hexagonpath"
        case .empty: return "square.dashed"
        }
    }

    var description: String {
        switch self {
        case .traditionalRows: return "Standard classroom rows facing front"
        case .pairs: return "Two-desk paired seating arrangement"
        case .groups: return "Clustered desk groups for collaboration"
        case .uShape: return "Horseshoe/U-shaped arrangement"
        case .labStations: return "Round tables for lab activities"
        case .choirLoft: return "Staggered concert-style seating"
        case .computerLab: return "Perimeter desks along walls"
        case .seminar: return "Single large conference table"
        case .theater: return "Curved rows like a theater"
        case .collaborativePods: return "Circular pods for group work"
        case .empty: return "Start with a blank canvas"
        }
    }

    var needsConfiguration: Bool {
        self != .empty
    }

    var category: TemplateCategory {
        switch self {
        case .traditionalRows, .pairs, .choirLoft, .theater:
            return .lecture
        case .groups, .collaborativePods, .labStations:
            return .collaborative
        case .uShape, .seminar:
            return .discussion
        case .computerLab:
            return .specialized
        case .empty:
            return .other
        }
    }

    var suggestedDeskType: DeskType {
        switch self {
        case .labStations, .collaborativePods:
            return .circle
        case .seminar:
            return .longRectangle
        case .groups:
            return .trapezoid
        default:
            return .rectangle
        }
    }

    static var categorized: [(TemplateCategory, [LayoutTemplate])] {
        let grouped = Dictionary(grouping: allCases) { $0.category }
        return TemplateCategory.allCases.compactMap { category in
            guard let templates = grouped[category], !templates.isEmpty else { return nil }
            return (category, templates)
        }
    }
}

enum TemplateCategory: String, CaseIterable, Identifiable {
    case lecture = "Lecture"
    case collaborative = "Collaborative"
    case discussion = "Discussion"
    case specialized = "Specialized"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .lecture: return "person.fill"
        case .collaborative: return "person.3.fill"
        case .discussion: return "bubble.left.and.bubble.right.fill"
        case .specialized: return "gearshape.fill"
        case .other: return "square.grid.2x2"
        }
    }
}

// MARK: - Layout Generation Extension
extension LayoutTemplate {
    // Default grid size matching DisplayOptions default
    static let defaultGridSize: CGFloat = 20

    // Helper function to snap a point to the grid
    private static func snapToGrid(_ point: CGPoint, gridSize: CGFloat) -> CGPoint {
        CGPoint(
            x: round(point.x / gridSize) * gridSize,
            y: round(point.y / gridSize) * gridSize
        )
    }

    // Generate desks with configuration - totalDesks is the hard limit
    // gridSize parameter ensures generated desks align with the editor grid
    func generateDesks(in roomSize: CGSize, config: TemplateConfiguration, gridSize: CGFloat = defaultGridSize) -> [Desk] {
        let centerX = roomSize.width / 2
        let centerY = roomSize.height / 2

        var desks: [Desk]

        switch self {
        case .traditionalRows:
            desks = generateTraditionalRows(centerX: centerX, centerY: centerY, config: config)
        case .pairs:
            desks = generatePairs(centerX: centerX, centerY: centerY, config: config)
        case .groups:
            desks = generateGroups(centerX: centerX, centerY: centerY, config: config)
        case .uShape:
            desks = generateUShape(centerX: centerX, centerY: centerY, config: config)
        case .labStations:
            desks = generateLabStations(centerX: centerX, centerY: centerY, config: config)
        case .choirLoft:
            desks = generateChoirLoft(centerX: centerX, centerY: centerY, config: config)
        case .computerLab:
            desks = generateComputerLab(centerX: centerX, centerY: centerY, config: config)
        case .seminar:
            desks = generateSeminar(centerX: centerX, centerY: centerY, config: config)
        case .theater:
            desks = generateTheater(centerX: centerX, centerY: centerY, config: config)
        case .collaborativePods:
            desks = generateCollaborativePods(centerX: centerX, centerY: centerY, config: config)
        case .empty:
            return []
        }

        // Snap all desk positions to grid for proper alignment
        return desks.map { desk in
            var snappedDesk = desk
            snappedDesk.position = Self.snapToGrid(desk.position, gridSize: gridSize)
            return snappedDesk
        }
    }

    // Issue 3: Fill desks from FRONT to BACK (high Y to low Y in iOS)
    private func generateTraditionalRows(centerX: CGFloat, centerY: CGFloat, config: TemplateConfiguration) -> [Desk] {
        var desks: [Desk] = []
        let spacing: CGFloat = 20
        let deskWidth: CGFloat = 80
        let deskHeight: CGFloat = 60

        let totalWidth = CGFloat(config.columns) * deskWidth + CGFloat(config.columns - 1) * spacing
        let totalHeight = CGFloat(config.rows) * deskHeight + CGFloat(config.rows - 1) * spacing
        let startX = centerX - totalWidth / 2 + deskWidth / 2
        // Start from bottom (high Y = front of room) and work up
        let startY = centerY + totalHeight / 2 - deskHeight / 2

        // Iterate rows from front (bottom/high Y) to back (top/low Y)
        for row in 0..<config.rows {
            for col in 0..<config.columns {
                if desks.count >= config.totalDesks { return desks }
                let x = startX + CGFloat(col) * (deskWidth + spacing)
                let y = startY - CGFloat(row) * (deskHeight + spacing) // Subtract to go up
                desks.append(Desk(position: CGPoint(x: x, y: y), type: .rectangle))
            }
        }
        return desks
    }

    // Issue 3: Fill desks from FRONT to BACK (high Y to low Y in iOS)
    private func generatePairs(centerX: CGFloat, centerY: CGFloat, config: TemplateConfiguration) -> [Desk] {
        var desks: [Desk] = []
        let spacing: CGFloat = 25
        let pairSpacing: CGFloat = 15
        let deskWidth: CGFloat = 80
        let deskHeight: CGFloat = 60

        let pairCols = max(1, config.pairColumns)
        let totalWidth = CGFloat(pairCols) * 2 * deskWidth + CGFloat(pairCols - 1) * spacing + CGFloat(pairCols) * pairSpacing
        let totalHeight = CGFloat(config.pairRows) * deskHeight + CGFloat(config.pairRows - 1) * spacing
        let startX = centerX - totalWidth / 2 + deskWidth / 2
        // Start from bottom (high Y = front of room)
        let startY = centerY + totalHeight / 2 - deskHeight / 2

        // Iterate rows from front (bottom) to back (top)
        for row in 0..<config.pairRows {
            for col in 0..<pairCols {
                let baseX = startX + CGFloat(col) * (2 * deskWidth + pairSpacing + spacing)
                let y = startY - CGFloat(row) * (deskHeight + spacing) // Subtract to go up

                if desks.count >= config.totalDesks { return desks }
                desks.append(Desk(position: CGPoint(x: baseX, y: y), type: .rectangle))

                if desks.count >= config.totalDesks { return desks }
                desks.append(Desk(position: CGPoint(x: baseX + deskWidth + pairSpacing, y: y), type: .rectangle))
            }
        }
        return desks
    }

    private func generateGroups(centerX: CGFloat, centerY: CGFloat, config: TemplateConfiguration) -> [Desk] {
        var desks: [Desk] = []
        let desksPerGroup = max(2, min(8, config.desksPerGroup))
        let numberOfGroups = config.numberOfGroups

        let groupCols = max(1, Int(ceil(sqrt(Double(numberOfGroups)))))
        let groupRows = Int(ceil(Double(numberOfGroups) / Double(groupCols)))

        let groupSpacing: CGFloat = 60
        let deskSize: CGFloat = 70
        let innerSpacing: CGFloat = 10

        let desksInRow = min(desksPerGroup, 4)
        let rowsInGroup = Int(ceil(Double(desksPerGroup) / Double(desksInRow)))

        let groupWidth = CGFloat(desksInRow) * deskSize + CGFloat(desksInRow - 1) * innerSpacing
        let groupHeight = CGFloat(rowsInGroup) * deskSize + CGFloat(rowsInGroup - 1) * innerSpacing

        let totalWidth = CGFloat(groupCols) * groupWidth + CGFloat(groupCols - 1) * groupSpacing
        let totalHeight = CGFloat(groupRows) * groupHeight + CGFloat(groupRows - 1) * groupSpacing
        let startX = centerX - totalWidth / 2 + groupWidth / 2
        let startY = centerY - totalHeight / 2 + groupHeight / 2

        var groupsCreated = 0

        for groupRow in 0..<groupRows {
            for groupCol in 0..<groupCols {
                if groupsCreated >= numberOfGroups || desks.count >= config.totalDesks { return desks }

                let groupCenterX = startX + CGFloat(groupCol) * (groupWidth + groupSpacing)
                let groupCenterY = startY + CGFloat(groupRow) * (groupHeight + groupSpacing)

                let gStartX = groupCenterX - groupWidth / 2 + deskSize / 2
                let gStartY = groupCenterY - groupHeight / 2 + deskSize / 2

                var desksPlaced = 0
                for dRow in 0..<rowsInGroup {
                    for dCol in 0..<desksInRow {
                        if desksPlaced >= desksPerGroup || desks.count >= config.totalDesks { break }
                        let x = gStartX + CGFloat(dCol) * (deskSize + innerSpacing)
                        let y = gStartY + CGFloat(dRow) * (deskSize + innerSpacing)
                        desks.append(Desk(position: CGPoint(x: x, y: y), type: .trapezoid))
                        desksPlaced += 1
                    }
                }
                groupsCreated += 1
            }
        }
        return desks
    }

    private func generateUShape(centerX: CGFloat, centerY: CGFloat, config: TemplateConfiguration) -> [Desk] {
        var desks: [Desk] = []
        let deskWidth: CGFloat = 80
        let deskHeight: CGFloat = 60
        let spacing: CGFloat = 20

        let topCount = config.uShapeTopCount
        let sideCount = config.uShapeSideCount

        let uWidth = CGFloat(max(topCount, 3)) * (deskWidth + spacing)
        let uHeight = CGFloat(max(sideCount, 1)) * (deskHeight + spacing) + 50

        // Top row (back of the room - seats face front)
        let topStartX = centerX - (CGFloat(topCount - 1) * (deskWidth + spacing)) / 2
        let topY = centerY - uHeight / 2

        for i in 0..<topCount {
            if desks.count >= config.totalDesks { return desks }
            let x = topStartX + CGFloat(i) * (deskWidth + spacing)
            desks.append(Desk(position: CGPoint(x: x, y: topY), type: .rectangle))
        }

        // Left column (going down toward front of room)
        let leftX = centerX - uWidth / 2
        let sideStartY = topY + deskHeight + spacing

        for i in 0..<sideCount {
            if desks.count >= config.totalDesks { return desks }
            let y = sideStartY + CGFloat(i) * (deskHeight + spacing)
            desks.append(Desk(position: CGPoint(x: leftX, y: y), type: .rectangle))
        }

        // Right column (going down toward front of room)
        let rightX = centerX + uWidth / 2
        for i in 0..<sideCount {
            if desks.count >= config.totalDesks { return desks }
            let y = sideStartY + CGFloat(i) * (deskHeight + spacing)
            desks.append(Desk(position: CGPoint(x: rightX, y: y), type: .rectangle))
        }

        return desks
    }

    private func generateLabStations(centerX: CGFloat, centerY: CGFloat, config: TemplateConfiguration) -> [Desk] {
        var desks: [Desk] = []
        let numberOfStations = config.numberOfStations
        let seatsPerStation = config.seatsPerStation

        let stationCols = max(1, Int(ceil(sqrt(Double(numberOfStations)))))
        let stationRows = Int(ceil(Double(numberOfStations) / Double(stationCols)))

        let spacing: CGFloat = 100
        let tableSize: CGFloat = 90

        let totalWidth = CGFloat(stationCols) * tableSize + CGFloat(stationCols - 1) * spacing
        let totalHeight = CGFloat(stationRows) * tableSize + CGFloat(stationRows - 1) * spacing
        let startX = centerX - totalWidth / 2 + tableSize / 2
        let startY = centerY - totalHeight / 2 + tableSize / 2

        var stationsCreated = 0

        for row in 0..<stationRows {
            for col in 0..<stationCols {
                if stationsCreated >= numberOfStations || desks.count >= config.totalDesks { return desks }
                let x = startX + CGFloat(col) * (tableSize + spacing)
                let y = startY + CGFloat(row) * (tableSize + spacing)
                desks.append(Desk(position: CGPoint(x: x, y: y), type: .circle, capacity: seatsPerStation))
                stationsCreated += 1
            }
        }
        return desks
    }

    // Issue 3: Fill desks from FRONT to BACK (high Y to low Y in iOS)
    private func generateChoirLoft(centerX: CGFloat, centerY: CGFloat, config: TemplateConfiguration) -> [Desk] {
        var desks: [Desk] = []
        let spacing: CGFloat = 15
        let deskWidth: CGFloat = 70
        let deskHeight: CGFloat = 50

        let rows = config.choirRows
        let columns = config.choirColumns

        let totalWidth = CGFloat(columns) * deskWidth + CGFloat(columns - 1) * spacing
        let totalHeight = CGFloat(rows) * deskHeight + CGFloat(rows - 1) * spacing
        let baseStartX = centerX - totalWidth / 2 + deskWidth / 2
        // Start from bottom (high Y = front of room)
        let startY = centerY + totalHeight / 2 - deskHeight / 2

        let staggerOffset = (deskWidth + spacing) / 2

        // Iterate rows from front (bottom) to back (top)
        for row in 0..<rows {
            let isStaggeredRow = row % 2 == 1
            let startX = isStaggeredRow ? baseStartX + staggerOffset : baseStartX
            let colsInRow = isStaggeredRow ? columns - 1 : columns

            for col in 0..<colsInRow {
                if desks.count >= config.totalDesks { return desks }
                let x = startX + CGFloat(col) * (deskWidth + spacing)
                let y = startY - CGFloat(row) * (deskHeight + spacing) // Subtract to go up
                desks.append(Desk(position: CGPoint(x: x, y: y), type: .rectangle))
            }
        }
        return desks
    }

    // MARK: - New Templates

    private func generateComputerLab(centerX: CGFloat, centerY: CGFloat, config: TemplateConfiguration) -> [Desk] {
        var desks: [Desk] = []
        let deskWidth: CGFloat = 80
        let deskHeight: CGFloat = 60
        let spacing: CGFloat = 20
        let wallMargin: CGFloat = 50

        let topCount = config.perimeterTopCount
        let bottomCount = config.perimeterBottomCount
        let sideCount = config.perimeterSideCount

        // Calculate room dimensions for perimeter
        let roomWidth = centerX * 2 - wallMargin * 2
        let roomHeight = centerY * 2 - wallMargin * 2

        // Top row (facing down into room)
        let topY = wallMargin + deskHeight / 2
        let topStartX = centerX - (CGFloat(topCount - 1) * (deskWidth + spacing)) / 2
        for i in 0..<topCount {
            if desks.count >= config.totalDesks { return desks }
            let x = topStartX + CGFloat(i) * (deskWidth + spacing)
            desks.append(Desk(position: CGPoint(x: x, y: topY), rotation: .degrees(180), type: .rectangle))
        }

        // Bottom row (facing up into room)
        let bottomY = roomHeight + wallMargin - deskHeight / 2
        let bottomStartX = centerX - (CGFloat(bottomCount - 1) * (deskWidth + spacing)) / 2
        for i in 0..<bottomCount {
            if desks.count >= config.totalDesks { return desks }
            let x = bottomStartX + CGFloat(i) * (deskWidth + spacing)
            desks.append(Desk(position: CGPoint(x: x, y: bottomY), type: .rectangle))
        }

        // Left column (facing right into room)
        let leftX = wallMargin + deskHeight / 2
        let sideStartY = topY + deskHeight + spacing
        for i in 0..<sideCount {
            if desks.count >= config.totalDesks { return desks }
            let y = sideStartY + CGFloat(i) * (deskHeight + spacing)
            desks.append(Desk(position: CGPoint(x: leftX, y: y), rotation: .degrees(90), type: .rectangle))
        }

        // Right column (facing left into room)
        let rightX = roomWidth + wallMargin - deskHeight / 2
        for i in 0..<sideCount {
            if desks.count >= config.totalDesks { return desks }
            let y = sideStartY + CGFloat(i) * (deskHeight + spacing)
            desks.append(Desk(position: CGPoint(x: rightX, y: y), rotation: .degrees(-90), type: .rectangle))
        }

        return desks
    }

    private func generateSeminar(centerX: CGFloat, centerY: CGFloat, config: TemplateConfiguration) -> [Desk] {
        var desks: [Desk] = []
        let tableLength = config.seminarTableLength
        let deskWidth: CGFloat = 180
        let deskHeight: CGFloat = 60
        let spacing: CGFloat = 10

        // Create two parallel long tables with seats on both sides
        let totalLength = CGFloat(tableLength / 2) * (deskWidth + spacing)
        let startX = centerX - totalLength / 2 + deskWidth / 2

        // Top side (seats facing down)
        let topY = centerY - deskHeight - spacing / 2
        for i in 0..<(tableLength / 2) {
            if desks.count >= config.totalDesks { return desks }
            let x = startX + CGFloat(i) * (deskWidth + spacing)
            desks.append(Desk(position: CGPoint(x: x, y: topY), type: .longRectangle, capacity: 2))
        }

        // Bottom side (seats facing up)
        let bottomY = centerY + deskHeight + spacing / 2
        for i in 0..<(tableLength / 2) {
            if desks.count >= config.totalDesks { return desks }
            let x = startX + CGFloat(i) * (deskWidth + spacing)
            desks.append(Desk(position: CGPoint(x: x, y: bottomY), type: .longRectangle, capacity: 2))
        }

        return desks
    }

    // Issue 3: Fill desks from FRONT to BACK (high Y to low Y in iOS)
    private func generateTheater(centerX: CGFloat, centerY: CGFloat, config: TemplateConfiguration) -> [Desk] {
        var desks: [Desk] = []
        let rows = config.theaterRows
        let baseColumns = config.theaterColumnsPerRow
        let curveAmount = config.theaterCurveAmount

        let deskWidth: CGFloat = 70
        let deskHeight: CGFloat = 50
        let rowSpacing: CGFloat = 25

        let totalHeight = CGFloat(rows) * (deskHeight + rowSpacing)
        // Start from bottom (high Y = front of room)
        let startY = centerY + totalHeight / 2 - deskHeight / 2

        // Iterate rows from front (bottom) to back (top)
        for row in 0..<rows {
            // Row progress now counts from front (0) to back (1)
            let rowProgress = CGFloat(row) / CGFloat(max(1, rows - 1))
            let curveOffset = rowProgress * curveAmount * CGFloat(baseColumns) * deskWidth * 0.2
            let columnsInRow = baseColumns

            let rowWidth = CGFloat(columnsInRow) * deskWidth + curveOffset * 2
            let startX = centerX - rowWidth / 2 + deskWidth / 2

            for col in 0..<columnsInRow {
                if desks.count >= config.totalDesks { return desks }

                // Calculate curved position
                let colProgress = CGFloat(col) / CGFloat(max(1, columnsInRow - 1)) - 0.5
                let curveY = abs(colProgress) * curveAmount * 30 * rowProgress

                let x = startX + CGFloat(col) * (deskWidth + curveOffset * 2 / CGFloat(columnsInRow))
                let y = startY - CGFloat(row) * (deskHeight + rowSpacing) + curveY // Subtract to go up

                desks.append(Desk(position: CGPoint(x: x, y: y), type: .rectangle))
            }
        }
        return desks
    }

    private func generateCollaborativePods(centerX: CGFloat, centerY: CGFloat, config: TemplateConfiguration) -> [Desk] {
        var desks: [Desk] = []
        let podCount = config.podCount
        let desksPerPod = min(8, max(4, config.desksPerPod))

        let podCols = max(1, Int(ceil(sqrt(Double(podCount)))))
        let podRows = Int(ceil(Double(podCount) / Double(podCols)))

        let podSpacing: CGFloat = 120
        let podRadius: CGFloat = 80

        let totalWidth = CGFloat(podCols) * podRadius * 2 + CGFloat(podCols - 1) * podSpacing
        let totalHeight = CGFloat(podRows) * podRadius * 2 + CGFloat(podRows - 1) * podSpacing
        let startX = centerX - totalWidth / 2 + podRadius
        let startY = centerY - totalHeight / 2 + podRadius

        var podsCreated = 0

        for podRow in 0..<podRows {
            for podCol in 0..<podCols {
                if podsCreated >= podCount || desks.count >= config.totalDesks { return desks }

                let podCenterX = startX + CGFloat(podCol) * (podRadius * 2 + podSpacing)
                let podCenterY = startY + CGFloat(podRow) * (podRadius * 2 + podSpacing)

                // Arrange desks in a circle around pod center
                for i in 0..<desksPerPod {
                    if desks.count >= config.totalDesks { return desks }

                    let angle = (2 * .pi / CGFloat(desksPerPod)) * CGFloat(i) - .pi / 2
                    let x = podCenterX + cos(angle) * podRadius
                    let y = podCenterY + sin(angle) * podRadius

                    // Rotate desks to face center
                    let rotation = Angle.radians(Double(angle) + .pi / 2)

                    desks.append(Desk(position: CGPoint(x: x, y: y), rotation: rotation, type: .trapezoid))
                }

                podsCreated += 1
            }
        }
        return desks
    }
}
