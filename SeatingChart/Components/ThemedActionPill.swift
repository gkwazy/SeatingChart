//
//  ThemedActionPill.swift
//  SeatingChart
//
//  Extracted from MainSeatingChartView for reusability
//  Action pill button with various style options
//

import SwiftUI

// MARK: - Themed Action Pill

struct ThemedActionPill: View {
    let title: String
    let icon: String
    let style: ActionPillStyle
    let action: () -> Void

    enum ActionPillStyle {
        case primary, secondary, success, danger, neutral

        var backgroundColor: Color {
            switch self {
            case .primary: return Theme.Colors.forest
            case .secondary: return Theme.Colors.amber
            case .success: return Theme.Colors.success
            case .danger: return Theme.Colors.danger
            case .neutral: return Theme.Colors.slate
            }
        }

        var textColor: Color {
            switch self {
            case .secondary: return Theme.Colors.charcoal
            default: return .white
            }
        }
    }

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(Theme.Typography.headline(14, weight: .semibold))
            }
            .foregroundColor(style.textColor)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(style.backgroundColor)
            .cornerRadius(Theme.Radius.full)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .pressEvents {
            withAnimation(Theme.Animation.pop) { isPressed = true }
        } onRelease: {
            withAnimation(Theme.Animation.pop) { isPressed = false }
        }
        .accessibilityLabel("\(title) button")
        .accessibilityHint("Double tap to \(title.lowercased())")
    }
}

// MARK: - Rules Action Pill

struct RulesActionPill: View {
    let ruleCount: Int
    let action: () -> Void

    @State private var isPressed = false
    @State private var badgeBounce = false

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: "person.2.wave.2")
                    .font(.system(size: 13, weight: .semibold))
                Text("Rules")
                    .font(Theme.Typography.caption(12, weight: .semibold))

                if ruleCount > 0 {
                    Text("\(ruleCount)")
                        .font(Theme.Typography.caption(10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Theme.Colors.coral)
                        .clipShape(Capsule())
                        .scaleEffect(badgeBounce ? 1.2 : 1.0)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(Theme.Colors.purple)
            .cornerRadius(Theme.Radius.full)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .pressEvents {
            withAnimation(Theme.Animation.pop) { isPressed = true }
        } onRelease: {
            withAnimation(Theme.Animation.pop) { isPressed = false }
        }
        .onAppear {
            if ruleCount > 0 {
                withAnimation(Theme.Animation.elastic.delay(0.5)) {
                    badgeBounce = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    withAnimation(Theme.Animation.elastic) {
                        badgeBounce = false
                    }
                }
            }
        }
        .accessibilityLabel("Seating rules")
        .accessibilityValue(ruleCount > 0 ? "\(ruleCount) rules active" : "No rules set")
    }
}

// MARK: - Legacy Action Button

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(.white)
            .frame(width: 70, height: 50)
            .background(color)
            .cornerRadius(8)
        }
        .accessibilityLabel(title)
    }
}

#Preview("Action Pills") {
    VStack(spacing: 20) {
        HStack(spacing: 12) {
            ThemedActionPill(
                title: "Attendance",
                icon: "checkmark.circle.fill",
                style: .success,
                action: {}
            )

            ThemedActionPill(
                title: "Random",
                icon: "shuffle",
                style: .primary,
                action: {}
            )
        }

        HStack(spacing: 12) {
            ThemedActionPill(
                title: "Save",
                icon: "square.and.arrow.down.fill",
                style: .primary,
                action: {}
            )

            ThemedActionPill(
                title: "Cancel",
                icon: "xmark.circle.fill",
                style: .danger,
                action: {}
            )
        }

        RulesActionPill(ruleCount: 3, action: {})
    }
    .padding()
    .background(Theme.Colors.ivory)
}
