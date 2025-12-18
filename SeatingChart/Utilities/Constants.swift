//
//  Constants.swift
//  SeatingChart
//
//  Updated with Schoolhouse Modern design tokens
//

import Foundation
import SwiftUI

struct Constants {
    // MARK: - Grid Configuration

    static let defaultGridWidth: Int16 = 8
    static let defaultGridHeight: Int16 = 5
    static let maxGridWidth: Int = 10
    static let maxGridHeight: Int = 8
    static let gridCellSize: CGFloat = 70
    static let gridSpacing: CGFloat = Theme.Spacing.sm

    // MARK: - Photo Configuration

    static let maxPhotoSize: CGFloat = 400
    static let photoCompressionQuality: CGFloat = 0.7
    static let thumbnailSize: CGFloat = 50

    // MARK: - Colors (Bridged from Theme)

    static let presentColor = Theme.Colors.success
    static let absentColor = Theme.Colors.danger
    static let tardyColor = Theme.Colors.warning
    static let deskOccupiedColor = Theme.Colors.amber.opacity(0.15)
    static let deskEmptyColor = Theme.Colors.linen
    static let deskBorderColor = Theme.Colors.stone

    // MARK: - Attendance Colors

    static let presentBackground = Theme.Colors.presentBg
    static let presentBorder = Theme.Colors.presentBorder
    static let tardyBackground = Theme.Colors.tardyBg
    static let tardyBorder = Theme.Colors.tardyBorder
    static let absentBackground = Theme.Colors.absentBg
    static let absentBorder = Theme.Colors.absentBorder

    // MARK: - Animation

    static let standardAnimation = Theme.Animation.snappy
    static let quickAnimation = Theme.Animation.smooth
    static let gentleAnimation = Theme.Animation.gentle
    static let bouncyAnimation = Theme.Animation.bouncy

    // MARK: - Layout

    static let cornerRadius: CGFloat = Theme.Radius.md
    static let smallCornerRadius: CGFloat = Theme.Radius.sm
    static let standardPadding: CGFloat = Theme.Spacing.md
    static let smallPadding: CGFloat = Theme.Spacing.xs

    // MARK: - Desk Dimensions

    struct DeskSize {
        static let standard = CGSize(width: 70, height: 55)
        static let square = CGSize(width: 60, height: 60)
        static let long = CGSize(width: 140, height: 55)
        static let circle = CGSize(width: 65, height: 65)
        static let trapezoid = CGSize(width: 80, height: 60)
    }

    // MARK: - Student Photo Sizes

    struct PhotoSize {
        static let deskThumbnail: CGFloat = 36
        static let rosterRow: CGFloat = 44
        static let detailView: CGFloat = 80
        static let fullSize: CGFloat = 120
    }
}
