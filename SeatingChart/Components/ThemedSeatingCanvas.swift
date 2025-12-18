//
//  ThemedSeatingCanvas.swift
//  SeatingChart
//
//  Extracted from MainSeatingChartView for reusability
//  Main canvas with zoom/pan for displaying the seating chart
//

import SwiftUI

// MARK: - Themed Seating Canvas

struct ThemedSeatingCanvas: View {
    let desks: [Desk]
    let students: [Student]
    let isTakingAttendance: Bool
    let attendanceStatus: [UUID: AttendanceStatus]
    let showPhotos: Bool
    let privacyMode: Bool
    let hasTodaysAttendance: Bool
    let onDeskTap: (Desk) -> Void
    let availableSize: CGSize

    private let deskPadding: CGFloat = 1.15

    @State private var currentZoom: CGFloat = 1.0
    @State private var lastZoom: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let maxZoom: CGFloat = 3.0
    private var minZoom: CGFloat { 0.7 }

    // MARK: - Computed Properties

    private var desksBounds: CGRect {
        guard !desks.isEmpty else {
            return CGRect(x: 0, y: 0, width: 400, height: 300)
        }

        let sumX = desks.reduce(0) { $0 + $1.position.x }
        let sumY = desks.reduce(0) { $0 + $1.position.y }
        let center = CGPoint(x: sumX / CGFloat(desks.count), y: sumY / CGFloat(desks.count))

        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude

        for desk in desks {
            let spreadX = center.x + (desk.position.x - center.x) * deskPadding
            let spreadY = center.y + (desk.position.y - center.y) * deskPadding

            minX = min(minX, spreadX - desk.size.width / 2)
            minY = min(minY, spreadY - desk.size.height / 2)
            maxX = max(maxX, spreadX + desk.size.width / 2)
            maxY = max(maxY, spreadY + desk.size.height / 2)
        }

        let edgePadding: CGFloat = 60
        return CGRect(
            x: minX - edgePadding,
            y: minY - edgePadding,
            width: maxX - minX + edgePadding * 2,
            height: maxY - minY + edgePadding * 2
        )
    }

    private var initialScale: CGFloat {
        let bounds = desksBounds
        guard bounds.width > 0 && bounds.height > 0 else { return 1.0 }

        let scaleX = availableSize.width / bounds.width
        let scaleY = availableSize.height / bounds.height
        let scale = min(scaleX, scaleY) * 0.9
        return max(min(scale, 1.5), 0.3)
    }

    private var totalScale: CGFloat {
        initialScale * currentZoom
    }

    private var desksCenter: CGPoint {
        guard !desks.isEmpty else { return .zero }
        let sumX = desks.reduce(0) { $0 + $1.position.x }
        let sumY = desks.reduce(0) { $0 + $1.position.y }
        return CGPoint(x: sumX / CGFloat(desks.count), y: sumY / CGFloat(desks.count))
    }

    private func spreadPosition(for desk: Desk) -> CGPoint {
        let center = desksCenter
        let spreadX = center.x + (desk.position.x - center.x) * deskPadding
        let spreadY = center.y + (desk.position.y - center.y) * deskPadding
        return CGPoint(x: spreadX, y: spreadY)
    }

    private var centerOffset: CGSize {
        let bounds = desksBounds
        return CGSize(
            width: availableSize.width / 2 - bounds.midX * totalScale,
            height: availableSize.height / 2 - bounds.midY * totalScale
        )
    }

    // MARK: - Helper Functions

    private func studentForDesk(_ desk: Desk) -> Student? {
        guard let studentID = desk.assignedStudentIDs.first else { return nil }
        return students.first(where: { $0.id == studentID })
    }

    private func statusForDesk(_ desk: Desk) -> AttendanceStatus? {
        guard let student = studentForDesk(desk),
              let studentID = student.id else {
            return nil
        }
        return attendanceStatus[studentID]
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Warm textured background
                Theme.Colors.ivory

                // Subtle grid pattern overlay
                gridPattern(size: geometry.size)

                // Desks
                desksLayer
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .gesture(magnificationGesture)
            .simultaneousGesture(dragGesture)
            .onTapGesture(count: 2) {
                resetZoom()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Seating chart with \(desks.count) desks")
        .accessibilityHint("Pinch to zoom, drag to pan, double tap to reset view")
    }

    // MARK: - View Components

    private func gridPattern(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let gridSize: CGFloat = 40
            let path = Path { p in
                for x in stride(from: 0, through: canvasSize.width, by: gridSize) {
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: canvasSize.height))
                }
                for y in stride(from: 0, through: canvasSize.height, by: gridSize) {
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: canvasSize.width, y: y))
                }
            }
            context.stroke(path, with: .color(Theme.Colors.linen), lineWidth: 1)
        }
        .opacity(0.5)
    }

    private var desksLayer: some View {
        ZStack {
            ForEach(desks) { desk in
                let spreadPos = spreadPosition(for: desk)
                ThemedDeskView(
                    desk: desk,
                    student: studentForDesk(desk),
                    status: statusForDesk(desk),
                    showPhoto: showPhotos,
                    privacyMode: privacyMode,
                    isTakingAttendance: isTakingAttendance,
                    showAttendanceColors: hasTodaysAttendance
                )
                .position(
                    x: spreadPos.x * totalScale + centerOffset.width + currentOffset.width,
                    y: spreadPos.y * totalScale + centerOffset.height + currentOffset.height
                )
                .scaleEffect(totalScale)
                .onTapGesture {
                    onDeskTap(desk)
                }
            }
        }
    }

    // MARK: - Gestures

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastZoom
                lastZoom = value
                let newZoom = currentZoom * delta
                currentZoom = min(max(newZoom, minZoom), maxZoom)
            }
            .onEnded { _ in
                lastZoom = 1.0
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                currentOffset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = currentOffset
            }
    }

    private func resetZoom() {
        withAnimation(Theme.Animation.bouncy) {
            currentZoom = 1.0
            lastZoom = 1.0
            currentOffset = .zero
            lastOffset = .zero
        }
    }

    // MARK: - Public Methods

    /// Reset zoom and pan to default state
    func resetView() {
        resetZoom()
    }
}

#Preview("Themed Seating Canvas") {
    ThemedSeatingCanvas(
        desks: [
            Desk(position: CGPoint(x: 100, y: 100), type: .rectangle),
            Desk(position: CGPoint(x: 200, y: 100), type: .rectangle),
            Desk(position: CGPoint(x: 100, y: 200), type: .rectangle),
            Desk(position: CGPoint(x: 200, y: 200), type: .rectangle)
        ],
        students: [],
        isTakingAttendance: false,
        attendanceStatus: [:],
        showPhotos: true,
        privacyMode: false,
        hasTodaysAttendance: false,
        onDeskTap: { _ in },
        availableSize: CGSize(width: 400, height: 600)
    )
    .frame(width: 400, height: 600)
}
