//
//  AttendanceStatusBadge.swift
//  SeatingChart
//
//  Created by GKWazy Software
//

import SwiftUI

struct AttendanceStatusBadge: View {
    let status: AttendanceStatus
    let size: CGFloat = 24

    var body: some View {
        Image(systemName: status.icon)
            .font(.system(size: size * 0.6))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(status.color)
            .clipShape(Circle())
    }
}

struct AttendanceStatusOverlay: View {
    let status: AttendanceStatus
    let borderWidth: CGFloat = 3

    var body: some View {
        RoundedRectangle(cornerRadius: Constants.smallCornerRadius)
            .strokeBorder(status.color, lineWidth: borderWidth)
    }
}

struct AttendanceStatusBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AttendanceStatusBadge(status: .present)
            AttendanceStatusBadge(status: .absent)
            AttendanceStatusBadge(status: .tardy)
        }
        .padding()
    }
}
