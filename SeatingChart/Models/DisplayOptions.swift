//
//  DisplayOptions.swift
//  SeatingChart
//
//  Created by GKWazy Software
//

import Foundation

struct DisplayOptions {
    var showStudentPhotos: Bool = true
    var showStudentNames: Bool = true
    var privacyBlur: Bool = false
    var showGrid: Bool = true
    var gridSize: CGFloat = 20

    static let `default` = DisplayOptions()
}
