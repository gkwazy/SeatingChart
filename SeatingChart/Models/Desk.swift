//
//  Desk.swift
//  SeatingChart
//
//  Created by Claude
//

import Foundation
import SwiftUI

struct Desk: Identifiable, Equatable {
    let id: UUID
    var position: CGPoint
    var rotation: Angle
    var size: CGSize
    var type: DeskType
    var capacity: Int
    var assignedStudentIDs: [UUID]

    init(
        id: UUID = UUID(),
        position: CGPoint = .zero,
        rotation: Angle = .zero,
        size: CGSize? = nil,
        type: DeskType = .rectangle,
        capacity: Int? = nil
    ) {
        self.id = id
        self.position = position
        self.rotation = rotation
        self.type = type
        self.size = size ?? type.defaultSize
        self.capacity = capacity ?? type.defaultCapacity
        self.assignedStudentIDs = []
    }

    // Codable support
    enum CodingKeys: String, CodingKey {
        case id, positionX, positionY, rotationDegrees, sizeWidth, sizeHeight, type, capacity, assignedStudentIDs
    }
}

extension Desk: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        let x = try container.decode(CGFloat.self, forKey: .positionX)
        let y = try container.decode(CGFloat.self, forKey: .positionY)
        position = CGPoint(x: x, y: y)

        let degrees = try container.decode(Double.self, forKey: .rotationDegrees)
        rotation = .degrees(degrees)

        let width = try container.decode(CGFloat.self, forKey: .sizeWidth)
        let height = try container.decode(CGFloat.self, forKey: .sizeHeight)
        size = CGSize(width: width, height: height)

        type = try container.decode(DeskType.self, forKey: .type)
        capacity = try container.decode(Int.self, forKey: .capacity)
        assignedStudentIDs = try container.decode([UUID].self, forKey: .assignedStudentIDs)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(position.x, forKey: .positionX)
        try container.encode(position.y, forKey: .positionY)
        try container.encode(rotation.degrees, forKey: .rotationDegrees)
        try container.encode(size.width, forKey: .sizeWidth)
        try container.encode(size.height, forKey: .sizeHeight)
        try container.encode(type, forKey: .type)
        try container.encode(capacity, forKey: .capacity)
        try container.encode(assignedStudentIDs, forKey: .assignedStudentIDs)
    }

    // Helper computed properties
    var isOccupied: Bool {
        !assignedStudentIDs.isEmpty
    }

    var isFull: Bool {
        assignedStudentIDs.count >= capacity
    }

    var availableSeats: Int {
        capacity - assignedStudentIDs.count
    }

    // Bounds for hit testing
    func bounds() -> CGRect {
        CGRect(
            x: position.x - size.width / 2,
            y: position.y - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    func contains(point: CGPoint) -> Bool {
        bounds().contains(point)
    }

    // Alignment helpers
    var centerX: CGFloat { position.x }
    var centerY: CGFloat { position.y }
    var minX: CGFloat { position.x - size.width / 2 }
    var maxX: CGFloat { position.x + size.width / 2 }
    var minY: CGFloat { position.y - size.height / 2 }
    var maxY: CGFloat { position.y + size.height / 2 }
}
