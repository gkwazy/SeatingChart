//
//  LayoutTemplate.swift
//  SeatingChart
//
//  Created by Claude
//

import Foundation
import SwiftUI

// Configuration struct for layout-specific parameters
// totalDesks is "the law" - templates will never exceed this number
struct TemplateConfiguration {
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

    var uShapeTotalSeats: Int {
        uShapeTopCount + (2 * uShapeSideCount)
    }
}

enum LayoutTemplate: String, CaseIterable, Identifiable {
    case traditionalRows
    case pairs
    case groups
    case uShape
    case labStations
    case choirLoft
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
        case .empty: return "square.dashed"
        }
    }

    var description: String {
        switch self {
        case .traditionalRows: return "Standard classroom rows"
        case .pairs: return "2-desk paired columns"
        case .groups: return "Clustered desk groups"
        case .uShape: return "Horseshoe arrangement"
        case .labStations: return "Round lab tables"
        case .choirLoft: return "Staggered concert seating"
        case .empty: return "Start from scratch"
        }
    }

    var needsConfiguration: Bool {
        self != .empty
    }

    // Generate desks with configuration - totalDesks is the hard limit
    func generateDesks(in roomSize: CGSize, config: TemplateConfiguration) -> [Desk] {
        let centerX = roomSize.width / 2
        let centerY = roomSize.height / 2

        switch self {
        case .traditionalRows:
            return generateTraditionalRows(centerX: centerX, centerY: centerY, config: config)
        case .pairs:
            return generatePairs(centerX: centerX, centerY: centerY, config: config)
        case .groups:
            return generateGroups(centerX: centerX, centerY: centerY, config: config)
        case .uShape:
            return generateUShape(centerX: centerX, centerY: centerY, config: config)
        case .labStations:
            return generateLabStations(centerX: centerX, centerY: centerY, config: config)
        case .choirLoft:
            return generateChoirLoft(centerX: centerX, centerY: centerY, config: config)
        case .empty:
            return []
        }
    }

    private func generateTraditionalRows(centerX: CGFloat, centerY: CGFloat, config: TemplateConfiguration) -> [Desk] {
        var desks: [Desk] = []
        let spacing: CGFloat = 20
        let deskWidth: CGFloat = 80
        let deskHeight: CGFloat = 60

        let totalWidth = CGFloat(config.columns) * deskWidth + CGFloat(config.columns - 1) * spacing
        let totalHeight = CGFloat(config.rows) * deskHeight + CGFloat(config.rows - 1) * spacing
        let startX = centerX - totalWidth / 2 + deskWidth / 2
        let startY = centerY - totalHeight / 2 + deskHeight / 2

        for row in 0..<config.rows {
            for col in 0..<config.columns {
                if desks.count >= config.totalDesks { return desks }
                let x = startX + CGFloat(col) * (deskWidth + spacing)
                let y = startY + CGFloat(row) * (deskHeight + spacing)
                desks.append(Desk(position: CGPoint(x: x, y: y), type: .rectangle))
            }
        }
        return desks
    }

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
        let startY = centerY - totalHeight / 2 + deskHeight / 2

        for row in 0..<config.pairRows {
            for col in 0..<pairCols {
                let baseX = startX + CGFloat(col) * (2 * deskWidth + pairSpacing + spacing)
                let y = startY + CGFloat(row) * (deskHeight + spacing)

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
        let startY = centerY - totalHeight / 2 + deskHeight / 2

        let staggerOffset = (deskWidth + spacing) / 2

        for row in 0..<rows {
            let isStaggeredRow = row % 2 == 1
            let startX = isStaggeredRow ? baseStartX + staggerOffset : baseStartX
            let colsInRow = isStaggeredRow ? columns - 1 : columns

            for col in 0..<colsInRow {
                if desks.count >= config.totalDesks { return desks }
                let x = startX + CGFloat(col) * (deskWidth + spacing)
                let y = startY + CGFloat(row) * (deskHeight + spacing)
                desks.append(Desk(position: CGPoint(x: x, y: y), type: .rectangle))
            }
        }
        return desks
    }
}
