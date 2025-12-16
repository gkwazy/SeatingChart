//
//  StorageMode.swift
//  SeatingChart
//
//  Created by Claude
//

import Foundation

enum StorageMode: String, Codable {
    case iCloud
    case local

    var displayName: String {
        switch self {
        case .iCloud:
            return "iCloud Sync"
        case .local:
            return "This Device Only"
        }
    }

    var description: String {
        switch self {
        case .iCloud:
            return "Your data syncs across iPhone, iPad, and any device signed into your iCloud. Requires iCloud to be enabled."
        case .local:
            return "Your data stays only on this device. Simpler and more private, but no backup or sync."
        }
    }

    var icon: String {
        switch self {
        case .iCloud:
            return "icloud.fill"
        case .local:
            return "iphone"
        }
    }
}
