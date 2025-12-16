//
//  DeskType.swift
//  SeatingChart
//
//  Created by Claude
//

import Foundation
import SwiftUI

enum DeskType: String, Codable, CaseIterable, Identifiable {
    case rectangle
    case square
    case trapezoid
    case circle
    case longRectangle

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rectangle: return "Rectangle"
        case .square: return "Square"
        case .trapezoid: return "Trapezoid"
        case .circle: return "Circle"
        case .longRectangle: return "Long Table"
        }
    }

    var icon: String {
        switch self {
        case .rectangle: return "rectangle"
        case .square: return "square"
        case .trapezoid: return "trapezoid"
        case .circle: return "circle"
        case .longRectangle: return "rectangle.split.3x1"
        }
    }

    var defaultSize: CGSize {
        switch self {
        case .rectangle: return CGSize(width: 80, height: 60)
        case .square: return CGSize(width: 60, height: 60)
        case .trapezoid: return CGSize(width: 80, height: 70)
        case .circle: return CGSize(width: 90, height: 90)
        case .longRectangle: return CGSize(width: 180, height: 60)
        }
    }

    var defaultCapacity: Int {
        switch self {
        case .rectangle: return 1
        case .square: return 1
        case .trapezoid: return 1
        case .circle: return 1
        case .longRectangle: return 3
        }
    }
}
