//
//  ViewMode.swift
//  SeatingChart
//
//  Created by GKWazy Software
//

import Foundation

enum ViewMode: String, CaseIterable, Identifiable {
    case edit
    case seating
    case attendance

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .edit: return "Edit"
        case .seating: return "Seating"
        case .attendance: return "Attendance"
        }
    }

    var icon: String {
        switch self {
        case .edit: return "square.and.pencil"
        case .seating: return "person.2.fill"
        case .attendance: return "checkmark.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .edit: return "Modify desk positions and room layout"
        case .seating: return "View and assign students to seats"
        case .attendance: return "Mark student attendance"
        }
    }
}
