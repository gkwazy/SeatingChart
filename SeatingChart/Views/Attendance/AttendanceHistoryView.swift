//
//  AttendanceHistoryView.swift
//  SeatingChart
//
//  Created on 2025-11-29.
//

import SwiftUI
import CoreData

struct AttendanceHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var classPeriod: ClassPeriod

    @State private var selectedDate: Date?
    @State private var showingExportView = false

    @FetchRequest private var attendanceRecords: FetchedResults<AttendanceRecord>

    init(classPeriod: ClassPeriod) {
        self.classPeriod = classPeriod

        _attendanceRecords = FetchRequest<AttendanceRecord>(
            sortDescriptors: [NSSortDescriptor(keyPath: \AttendanceRecord.date, ascending: false)],
            predicate: NSPredicate(format: "classPeriod == %@", classPeriod),
            animation: .default
        )
    }

    var groupedRecords: [Date: [AttendanceRecord]] {
        Dictionary(grouping: attendanceRecords) { record in
            Calendar.current.startOfDay(for: record.date ?? Date())
        }
    }

    var sortedDates: [Date] {
        groupedRecords.keys.sorted(by: >)
    }

    var body: some View {
        ZStack {
            Theme.Colors.ivory
                .ignoresSafeArea()

            if sortedDates.isEmpty {
                // Friendly empty state
                VStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.sky.opacity(0.15))
                            .frame(width: 100, height: 100)

                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(Theme.Colors.sky)
                    }

                    VStack(spacing: Theme.Spacing.xs) {
                        Text("No Attendance Yet")
                            .font(Theme.Typography.display(20, weight: .semibold))
                            .foregroundColor(Theme.Colors.charcoal)

                        Text("Take attendance from the seating chart\nto see history here")
                            .font(Theme.Typography.body(15))
                            .foregroundColor(Theme.Colors.slate)
                            .multilineTextAlignment(.center)
                    }

                    // Helpful tip
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.amber)

                        Text("Tap 'Attendance' on the seating chart to start")
                            .font(Theme.Typography.caption(13))
                            .foregroundColor(Theme.Colors.slate)
                    }
                    .padding(Theme.Spacing.sm)
                    .background(Theme.Colors.amberLight)
                    .cornerRadius(Theme.Radius.sm)
                    .padding(.top, Theme.Spacing.sm)
                }
            } else {
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        ForEach(sortedDates, id: \.self) { date in
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                // Date header
                                Text(date.formatted(date: .complete, time: .omitted))
                                    .font(Theme.Typography.caption(11, weight: .semibold))
                                    .foregroundColor(Theme.Colors.slate)
                                    .textCase(.uppercase)
                                    .tracking(0.5)
                                    .padding(.horizontal, Theme.Spacing.md)

                                // Summary card with class name (Day > Class > Stats hierarchy)
                                if let records = groupedRecords[date] {
                                    Button {
                                        selectedDate = date
                                    } label: {
                                        ThemedAttendanceSummaryRow(
                                            records: records,
                                            classPeriodName: classPeriod.name
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, Theme.Spacing.md)
                                }
                            }
                        }
                    }
                    .padding(.vertical, Theme.Spacing.md)
                }
            }
        }
        .navigationTitle("Attendance History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingExportView = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(sortedDates.isEmpty)
            }
        }
        .sheet(item: $selectedDate) { date in
            AttendanceDetailSheet(
                classPeriod: classPeriod,
                date: date,
                records: groupedRecords[date] ?? []
            )
        }
        .sheet(isPresented: $showingExportView) {
            AttendanceExportView(classPeriod: classPeriod)
        }
    }
}

// MARK: - Themed Attendance Summary Row

struct ThemedAttendanceSummaryRow: View {
    let records: [AttendanceRecord]
    var classPeriodName: String? = nil

    var summary: (present: Int, absent: Int, tardy: Int, total: Int) {
        var present = 0
        var absent = 0
        var tardy = 0

        for record in records {
            switch record.attendanceStatus {
            case .present: present += 1
            case .absent: absent += 1
            case .tardy: tardy += 1
            }
        }

        return (present, absent, tardy, present + absent + tardy)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Class period name header (Day > CLASS > Stats hierarchy)
            if let name = classPeriodName {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.forest)
                    Text(name)
                        .font(Theme.Typography.headline(14, weight: .semibold))
                        .foregroundColor(Theme.Colors.charcoal)
                }
            }

            // Stats row
            HStack(spacing: Theme.Spacing.sm) {
                themedStatBadge(
                    count: summary.present,
                    label: "Present",
                    icon: "checkmark.circle.fill",
                    color: Theme.Colors.success,
                    bgColor: Theme.Colors.presentBg
                )

                themedStatBadge(
                    count: summary.absent,
                    label: "Absent",
                    icon: "xmark.circle.fill",
                    color: Theme.Colors.coral,
                    bgColor: Theme.Colors.absentBg
                )

                themedStatBadge(
                    count: summary.tardy,
                    label: "Tardy",
                    icon: "clock.fill",
                    color: Theme.Colors.amber,
                    bgColor: Theme.Colors.tardyBg
                )
            }

            // Total students and view details
            HStack {
                Text("\(summary.total) students recorded")
                    .font(Theme.Typography.caption(12))
                    .foregroundColor(Theme.Colors.slate)

                Spacer()

                HStack(spacing: 4) {
                    Text("View details")
                        .font(Theme.Typography.caption(12, weight: .medium))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(Theme.Colors.forest)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Color.white)
        .cornerRadius(Theme.Radius.md)
        .themeShadow(Theme.Shadows.subtle)
    }

    private func themedStatBadge(count: Int, label: String, icon: String, color: Color, bgColor: Color) -> some View {
        VStack(spacing: Theme.Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)

            Text("\(count)")
                .font(Theme.Typography.headline(18, weight: .bold))
                .foregroundColor(Theme.Colors.charcoal)

            Text(label)
                .font(Theme.Typography.caption(10, weight: .medium))
                .foregroundColor(Theme.Colors.slate)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm)
        .background(bgColor)
        .cornerRadius(Theme.Radius.sm)
    }
}

struct AttendanceDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    let classPeriod: ClassPeriod
    let date: Date
    let records: [AttendanceRecord]

    @State private var isEditMode = false
    @State private var isAuthenticated = false
    @State private var showingAuthPrompt = false
    @State private var authError: String?

    // Group by the actual status values (lowercase: present, absent, tardy)
    var groupedByStatus: [AttendanceStatus: [AttendanceRecord]] {
        Dictionary(grouping: records) { $0.attendanceStatus }
    }

    // Summary counts
    var summary: (present: Int, absent: Int, tardy: Int) {
        (
            present: groupedByStatus[.present]?.count ?? 0,
            absent: groupedByStatus[.absent]?.count ?? 0,
            tardy: groupedByStatus[.tardy]?.count ?? 0
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.ivory
                    .ignoresSafeArea()

                if records.isEmpty {
                    // Empty state
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.Colors.slate)
                        Text("No attendance records for this date")
                            .font(Theme.Typography.body(15))
                            .foregroundColor(Theme.Colors.slate)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: Theme.Spacing.lg) {
                            // Summary card at top
                            summaryCard

                            // Show absent and tardy students prominently
                            if summary.absent > 0 || summary.tardy > 0 {
                                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                                    // Absent section
                                    if let absentRecords = groupedByStatus[.absent], !absentRecords.isEmpty {
                                        statusSection(
                                            title: "Absent",
                                            records: absentRecords,
                                            color: Theme.Colors.coral,
                                            icon: "xmark.circle.fill"
                                        )
                                    }

                                    // Tardy section
                                    if let tardyRecords = groupedByStatus[.tardy], !tardyRecords.isEmpty {
                                        statusSection(
                                            title: "Tardy",
                                            records: tardyRecords,
                                            color: Theme.Colors.amber,
                                            icon: "clock.fill"
                                        )
                                    }
                                }
                                .padding(.horizontal, Theme.Spacing.md)
                            }

                            // Present section (collapsible or at bottom)
                            if let presentRecords = groupedByStatus[.present], !presentRecords.isEmpty {
                                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Theme.Colors.success)
                                        Text("Present (\(presentRecords.count))")
                                            .font(Theme.Typography.headline(16, weight: .semibold))
                                            .foregroundColor(Theme.Colors.charcoal)
                                    }
                                    .padding(.horizontal, Theme.Spacing.md)

                                    LazyVStack(spacing: Theme.Spacing.xs) {
                                        ForEach(presentRecords.sorted(by: {
                                            ($0.student?.lastName ?? "") < ($1.student?.lastName ?? "")
                                        })) { record in
                                            if let student = record.student {
                                                studentRow(record: record, student: student, compact: true)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, Theme.Spacing.md)
                                }
                            }
                        }
                        .padding(.vertical, Theme.Spacing.md)
                    }
                }

                // Authentication prompt overlay
                if showingAuthPrompt {
                    authPromptOverlay
                }
            }
            .navigationTitle(date.formatted(date: .abbreviated, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditMode && isAuthenticated {
                        Button("Cancel") {
                            withAnimation {
                                isEditMode = false
                                isAuthenticated = false
                            }
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditMode && isAuthenticated {
                        Button("Done") {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    } else {
                        HStack(spacing: 16) {
                            Button {
                                showingAuthPrompt = true
                            } label: {
                                Image(systemName: "pencil")
                            }

                            Button("Done") {
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.md) {
                summaryBadge(count: summary.present, label: "Present", color: Theme.Colors.success, bgColor: Theme.Colors.presentBg)
                summaryBadge(count: summary.absent, label: "Absent", color: Theme.Colors.coral, bgColor: Theme.Colors.absentBg)
                summaryBadge(count: summary.tardy, label: "Tardy", color: Theme.Colors.amber, bgColor: Theme.Colors.tardyBg)
            }

            Text("\(records.count) students total")
                .font(Theme.Typography.caption(12))
                .foregroundColor(Theme.Colors.slate)
        }
        .padding(Theme.Spacing.md)
        .background(Color.white)
        .cornerRadius(Theme.Radius.md)
        .themeShadow(Theme.Shadows.subtle)
        .padding(.horizontal, Theme.Spacing.md)
    }

    private func summaryBadge(count: Int, label: String, color: Color, bgColor: Color) -> some View {
        VStack(spacing: Theme.Spacing.xxs) {
            Text("\(count)")
                .font(Theme.Typography.headline(24, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(Theme.Typography.caption(11, weight: .medium))
                .foregroundColor(Theme.Colors.slate)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm)
        .background(bgColor)
        .cornerRadius(Theme.Radius.sm)
    }

    // MARK: - Status Section

    private func statusSection(title: String, records: [AttendanceRecord], color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text("\(title) (\(records.count))")
                    .font(Theme.Typography.headline(16, weight: .semibold))
                    .foregroundColor(Theme.Colors.charcoal)
            }

            VStack(spacing: 0) {
                ForEach(records.sorted(by: {
                    ($0.student?.lastName ?? "") < ($1.student?.lastName ?? "")
                })) { record in
                    if let student = record.student {
                        studentRow(record: record, student: student, compact: false)
                        if record.id != records.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(Theme.Radius.md)
            .themeShadow(Theme.Shadows.subtle)
        }
    }

    // MARK: - Student Row

    private func studentRow(record: AttendanceRecord, student: Student, compact: Bool) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Photo
            if let photoData = student.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: compact ? 32 : 40, height: compact ? 32 : 40)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Theme.Colors.slate.opacity(0.2))
                    .frame(width: compact ? 32 : 40, height: compact ? 32 : 40)
                    .overlay(
                        Text(student.initials ?? "?")
                            .font(Theme.Typography.caption(compact ? 10 : 12, weight: .medium))
                            .foregroundColor(Theme.Colors.slate)
                    )
            }

            // Name
            Text("\(student.firstName ?? "") \(student.lastName ?? "")")
                .font(Theme.Typography.body(compact ? 14 : 15))
                .foregroundColor(Theme.Colors.charcoal)

            Spacer()

            // Edit mode: status picker
            if isEditMode && isAuthenticated {
                Menu {
                    ForEach(AttendanceStatus.allCases, id: \.self) { status in
                        Button {
                            updateAttendanceStatus(record: record, newStatus: status.rawValue)
                        } label: {
                            HStack {
                                Text(status.displayName)
                                if record.attendanceStatus == status {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(record.attendanceStatus.displayName)
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(statusColor(for: record.attendanceStatus))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusColor(for: record.attendanceStatus).opacity(0.15))
                    .cornerRadius(8)
                }
            }
        }
        .padding(Theme.Spacing.sm)
        .background(compact ? Theme.Colors.ivory.opacity(0.5) : Color.white)
        .cornerRadius(compact ? Theme.Radius.sm : 0)
    }

    private func statusColor(for status: AttendanceStatus) -> Color {
        switch status {
        case .present: return Theme.Colors.success
        case .absent: return Theme.Colors.coral
        case .tardy: return Theme.Colors.amber
        }
    }

    // MARK: - Auth Prompt Overlay

    private var authPromptOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showingAuthPrompt = false
                }

            VStack(spacing: Theme.Spacing.lg) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Theme.Colors.sky.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: BiometricAuthManager.shared.biometricIcon)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(Theme.Colors.sky)
                }

                // Title and description
                VStack(spacing: Theme.Spacing.xs) {
                    Text("Edit Attendance")
                        .font(Theme.Typography.headline(18, weight: .semibold))
                        .foregroundColor(Theme.Colors.charcoal)

                    Text("Use \(BiometricAuthManager.shared.biometricName) to edit past attendance records")
                        .font(Theme.Typography.body(14))
                        .foregroundColor(Theme.Colors.slate)
                        .multilineTextAlignment(.center)
                }

                // Error message
                if let error = authError {
                    Text(error)
                        .font(Theme.Typography.caption(12))
                        .foregroundColor(Theme.Colors.coral)
                        .padding(.horizontal)
                }

                // Authenticate button
                Button {
                    authenticateForEdit()
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: BiometricAuthManager.shared.biometricIcon)
                        Text("Authenticate")
                    }
                    .font(Theme.Typography.body(16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(Theme.Colors.forest)
                    .cornerRadius(Theme.Radius.md)
                }
                .padding(.horizontal)

                // Cancel button
                Button("Cancel") {
                    showingAuthPrompt = false
                    authError = nil
                }
                .font(Theme.Typography.body(14))
                .foregroundColor(Theme.Colors.slate)
            }
            .padding(Theme.Spacing.xl)
            .background(Color.white)
            .cornerRadius(Theme.Radius.lg)
            .padding(.horizontal, Theme.Spacing.xl)
            .themeShadow(Theme.Shadows.elevated)
        }
    }

    // MARK: - Authentication

    private func authenticateForEdit() {
        Task {
            let result = await BiometricAuthManager.shared.authenticate(
                reason: "Authenticate to edit attendance records for \(date.formatted(date: .abbreviated, time: .omitted))"
            )

            switch result {
            case .success:
                withAnimation {
                    isAuthenticated = true
                    isEditMode = true
                    showingAuthPrompt = false
                    authError = nil
                }
            case .failure(let error):
                authError = error.localizedDescription
            case .cancelled:
                showingAuthPrompt = false
                authError = nil
            }
        }
    }

    // MARK: - Update Attendance

    private func updateAttendanceStatus(record: AttendanceRecord, newStatus: String) {
        record.status = newStatus

        do {
            try viewContext.save()
        } catch {
            #if DEBUG
            print("Error saving attendance update: \(error.localizedDescription)")
            #endif
        }
    }
}

extension Date: Identifiable {
    public var id: TimeInterval {
        self.timeIntervalSince1970
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let classPeriod = ClassPeriod(context: context)
    classPeriod.id = UUID()
    classPeriod.name = "Period 1"

    return NavigationStack {
        AttendanceHistoryView(classPeriod: classPeriod)
            .environment(\.managedObjectContext, context)
    }
}
