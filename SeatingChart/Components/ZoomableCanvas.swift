//
//  ZoomableCanvas.swift
//  SeatingChart
//
//  Created by Claude
//

import SwiftUI

struct ZoomableCanvas<Content: View>: View {
    @ViewBuilder let content: () -> Content

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    let minZoom: CGFloat = 0.5
    let maxZoom: CGFloat = 3.0

    var body: some View {
        GeometryReader { geometry in
            content()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            let newScale = scale * delta
                            scale = min(max(newScale, minZoom), maxZoom)
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                        }
                )
                // This gesture will be lower priority than desk gestures
                .background(
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 10)
                                .onChanged { value in
                                    // Canvas panning - will only activate on background
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // Helper to reset view
    func resetView() {
        withAnimation(.spring(response: 0.3)) {
            scale = 1.0
            lastScale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }

    // Helper to zoom to fit content
    func zoomToFit(contentSize: CGSize, in containerSize: CGSize) {
        let scaleX = containerSize.width / contentSize.width
        let scaleY = containerSize.height / contentSize.height
        let newScale = min(scaleX, scaleY, 1.0) * 0.9 // 90% to add padding

        withAnimation(.spring(response: 0.3)) {
            scale = min(max(newScale, minZoom), maxZoom)
            offset = .zero
            lastOffset = .zero
        }
    }
}

#Preview {
    ZoomableCanvas {
        VStack(spacing: 20) {
            ForEach(0..<10) { row in
                HStack(spacing: 20) {
                    ForEach(0..<5) { col in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 80, height: 60)
                            .overlay(
                                Text("\(row),\(col)")
                                    .font(.caption)
                            )
                    }
                }
            }
        }
        .padding(50)
    }
}
