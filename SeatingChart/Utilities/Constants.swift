//
//  Constants.swift
//  SeatingChart
//
//  Created by Claude
//

import Foundation
import SwiftUI

struct Constants {
    // Grid Configuration
    static let defaultGridWidth: Int16 = 8
    static let defaultGridHeight: Int16 = 5
    static let maxGridWidth: Int = 10
    static let maxGridHeight: Int = 8
    static let gridCellSize: CGFloat = 60
    static let gridSpacing: CGFloat = 8

    // Photo Configuration
    static let maxPhotoSize: CGFloat = 400
    static let photoCompressionQuality: CGFloat = 0.7
    static let thumbnailSize: CGFloat = 50

    // Colors
    static let presentColor = Color.green
    static let absentColor = Color.red
    static let tardyColor = Color.yellow
    static let deskOccupiedColor = Color.blue.opacity(0.3)
    static let deskEmptyColor = Color.gray.opacity(0.2)
    static let deskBorderColor = Color.gray.opacity(0.5)

    // Animation
    static let standardAnimation = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let quickAnimation = Animation.easeInOut(duration: 0.2)

    // Layout
    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    static let standardPadding: CGFloat = 16
    static let smallPadding: CGFloat = 8
}
