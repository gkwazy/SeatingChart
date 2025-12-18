#!/usr/bin/env swift

import Foundation
import AppKit

// Chair icon generator for SeatingChart app
// Creates a friendly chair/desk icon with emerald green color scheme

func generateAppIcon(size: Int, isDark: Bool = false) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let scale = CGFloat(size) / 1024.0

    // Background - rounded square with gradient
    let bgPath = NSBezierPath(roundedRect: rect.insetBy(dx: 0, dy: 0), xRadius: CGFloat(size) * 0.22, yRadius: CGFloat(size) * 0.22)

    if isDark {
        // Dark mode: darker emerald background
        NSColor(red: 0.04, green: 0.35, blue: 0.28, alpha: 1.0).setFill()
    } else {
        // Light mode: emerald green gradient
        NSColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0).setFill()
    }
    bgPath.fill()

    // Add subtle gradient overlay
    let gradientRect = rect.insetBy(dx: CGFloat(size) * 0.02, dy: CGFloat(size) * 0.02)
    let gradientPath = NSBezierPath(roundedRect: gradientRect, xRadius: CGFloat(size) * 0.20, yRadius: CGFloat(size) * 0.20)

    if isDark {
        NSColor(red: 0.06, green: 0.45, blue: 0.35, alpha: 0.5).setFill()
    } else {
        NSColor(red: 0.10, green: 0.80, blue: 0.55, alpha: 0.4).setFill()
    }
    gradientPath.fill()

    // Chair/desk icon - stylized classroom chair
    let iconColor = NSColor.white
    iconColor.setFill()
    iconColor.setStroke()

    let centerX = CGFloat(size) / 2
    let centerY = CGFloat(size) / 2

    // Chair seat (horizontal rectangle)
    let seatWidth = CGFloat(size) * 0.45
    let seatHeight = CGFloat(size) * 0.08
    let seatY = centerY - CGFloat(size) * 0.02
    let seatRect = NSRect(x: centerX - seatWidth/2, y: seatY, width: seatWidth, height: seatHeight)
    let seatPath = NSBezierPath(roundedRect: seatRect, xRadius: seatHeight * 0.4, yRadius: seatHeight * 0.4)
    seatPath.fill()

    // Chair back (vertical rectangle)
    let backWidth = CGFloat(size) * 0.08
    let backHeight = CGFloat(size) * 0.32
    let backX = centerX - seatWidth/2 + CGFloat(size) * 0.05
    let backY = seatY + seatHeight - CGFloat(size) * 0.02
    let backRect = NSRect(x: backX, y: backY, width: backWidth, height: backHeight)
    let backPath = NSBezierPath(roundedRect: backRect, xRadius: backWidth * 0.3, yRadius: backWidth * 0.3)
    backPath.fill()

    // Desk surface attached to chair (angled tablet arm)
    let deskWidth = CGFloat(size) * 0.22
    let deskHeight = CGFloat(size) * 0.06
    let deskX = centerX + CGFloat(size) * 0.02
    let deskY = seatY + seatHeight + CGFloat(size) * 0.08
    let deskRect = NSRect(x: deskX, y: deskY, width: deskWidth, height: deskHeight)
    let deskPath = NSBezierPath(roundedRect: deskRect, xRadius: deskHeight * 0.4, yRadius: deskHeight * 0.4)
    deskPath.fill()

    // Desk support arm
    let armWidth = CGFloat(size) * 0.04
    let armHeight = CGFloat(size) * 0.12
    let armX = deskX + CGFloat(size) * 0.02
    let armY = seatY + seatHeight - CGFloat(size) * 0.02
    let armRect = NSRect(x: armX, y: armY, width: armWidth, height: armHeight)
    let armPath = NSBezierPath(roundedRect: armRect, xRadius: armWidth * 0.3, yRadius: armWidth * 0.3)
    armPath.fill()

    // Chair legs (4 legs)
    let legWidth = CGFloat(size) * 0.04
    let legHeight = CGFloat(size) * 0.18
    let legY = seatY - legHeight

    // Front left leg
    let leg1Rect = NSRect(x: centerX - seatWidth/2 + CGFloat(size) * 0.06, y: legY, width: legWidth, height: legHeight)
    let leg1Path = NSBezierPath(roundedRect: leg1Rect, xRadius: legWidth * 0.3, yRadius: legWidth * 0.3)
    leg1Path.fill()

    // Front right leg
    let leg2Rect = NSRect(x: centerX + seatWidth/2 - CGFloat(size) * 0.10, y: legY, width: legWidth, height: legHeight)
    let leg2Path = NSBezierPath(roundedRect: leg2Rect, xRadius: legWidth * 0.3, yRadius: legWidth * 0.3)
    leg2Path.fill()

    // Back left leg
    let leg3Rect = NSRect(x: backX + CGFloat(size) * 0.02, y: legY, width: legWidth, height: legHeight)
    let leg3Path = NSBezierPath(roundedRect: leg3Rect, xRadius: legWidth * 0.3, yRadius: legWidth * 0.3)
    leg3Path.fill()

    // Back right leg
    let leg4Rect = NSRect(x: centerX + seatWidth/2 - CGFloat(size) * 0.10, y: legY, width: legWidth, height: legHeight)
    let leg4Path = NSBezierPath(roundedRect: leg4Rect, xRadius: legWidth * 0.3, yRadius: legWidth * 0.3)
    leg4Path.fill()

    image.unlockFocus()
    return image
}

func saveImage(_ image: NSImage, to path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmapRep = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG data for \(path)")
        return
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        print("✓ Created: \(path)")
    } catch {
        print("Failed to write \(path): \(error)")
    }
}

// Generate all required sizes
let basePath = "SeatingChart/Assets.xcassets/AppIcon.appiconset"

// iOS icons (1024x1024)
saveImage(generateAppIcon(size: 1024, isDark: false), to: "\(basePath)/AppIcon.png")
saveImage(generateAppIcon(size: 1024, isDark: true), to: "\(basePath)/AppIcon-Dark.png")

// macOS icons
saveImage(generateAppIcon(size: 16, isDark: false), to: "\(basePath)/AppIcon-16.png")
saveImage(generateAppIcon(size: 32, isDark: false), to: "\(basePath)/AppIcon-32.png")
saveImage(generateAppIcon(size: 64, isDark: false), to: "\(basePath)/AppIcon-64.png")
saveImage(generateAppIcon(size: 128, isDark: false), to: "\(basePath)/AppIcon-128.png")
saveImage(generateAppIcon(size: 256, isDark: false), to: "\(basePath)/AppIcon-256.png")
saveImage(generateAppIcon(size: 512, isDark: false), to: "\(basePath)/AppIcon-512.png")

print("\n🎉 App icons generated successfully!")
