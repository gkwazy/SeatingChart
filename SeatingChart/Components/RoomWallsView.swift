//
//  RoomWallsView.swift
//  SeatingChart
//
//  Created by Claude
//

import SwiftUI

struct RoomWallsView: View {
    let size: CGSize
    let wallThickness: CGFloat = 4
    let wallColor: Color = .gray
    let frontColor: Color = .blue

    var body: some View {
        ZStack {
            // Left wall
            Rectangle()
                .fill(wallColor)
                .frame(width: wallThickness, height: size.height)
                .position(x: 0, y: size.height / 2)

            // Right wall
            Rectangle()
                .fill(wallColor)
                .frame(width: wallThickness, height: size.height)
                .position(x: size.width, y: size.height / 2)

            // Back wall (top)
            Rectangle()
                .fill(wallColor)
                .frame(width: size.width, height: wallThickness)
                .position(x: size.width / 2, y: 0)

            // Front wall (bottom) - highlighted in blue
            Rectangle()
                .fill(frontColor)
                .frame(width: size.width, height: wallThickness * 1.5)
                .position(x: size.width / 2, y: size.height)

            // Front of class label
            VStack(spacing: 8) {
                Spacer()

                ZStack {
                    // Background pill
                    Capsule()
                        .fill(frontColor)
                        .frame(width: 160, height: 36)
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

                    // Text
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.fill.on.rectangle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)

                        Text("Front of Class")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .offset(y: -25)
            }
            .frame(width: size.width, height: size.height)
        }
        .frame(width: size.width, height: size.height)
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        RoomWallsView(size: CGSize(width: 1000, height: 800))
    }
}
