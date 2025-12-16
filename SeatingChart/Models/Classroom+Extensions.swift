//
//  Classroom+Extensions.swift
//  SeatingChart
//
//  Created by Claude
//

import Foundation
import CoreData

extension Classroom {
    var deskPositionsArray: [[Int]] {
        get {
            guard let data = deskPositions else { return [] }
            return (try? JSONDecoder().decode([[Int]].self, from: data)) ?? []
        }
        set {
            deskPositions = try? JSONEncoder().encode(newValue)
        }
    }

    var classesArray: [ClassPeriod] {
        let set = classes as? Set<ClassPeriod> ?? []
        return set.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    var totalDesks: Int {
        deskPositionsArray.count
    }

    convenience init(context: NSManagedObjectContext, name: String, width: Int16, height: Int16) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.gridWidth = width
        self.gridHeight = height
        self.createdAt = Date()
        self.deskPositionsArray = []
    }

    func hasDeskAt(x: Int, y: Int) -> Bool {
        deskPositionsArray.contains { $0[0] == x && $0[1] == y }
    }

    func addDesk(x: Int, y: Int) {
        var positions = deskPositionsArray
        if !positions.contains(where: { $0[0] == x && $0[1] == y }) {
            positions.append([x, y])
            deskPositionsArray = positions
        }
    }

    func removeDesk(x: Int, y: Int) {
        var positions = deskPositionsArray
        positions.removeAll { $0[0] == x && $0[1] == y }
        deskPositionsArray = positions
    }
}
