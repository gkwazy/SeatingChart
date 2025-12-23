//
//  Theme.swift
//  SeatingChart
//
//  Light-hearted, friendly design system
//  Warm, approachable colors for a classroom app
//  Supports both light and dark mode
//

import SwiftUI

// MARK: - Design Tokens

struct Theme {

    // MARK: - Color Palette (Warm, friendly classroom colors with Dark Mode support)

    struct Colors {
        // Primary - Friendly teal/green (adapts to dark mode)
        static var primary: Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.20, green: 0.83, blue: 0.60, alpha: 1.0)  // Brighter for dark
                    : UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0)  // #10B981
            })
        }
        static var primaryLight: Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.20, green: 0.60, blue: 0.45, alpha: 1.0)
                    : UIColor(red: 0.43, green: 0.91, blue: 0.72, alpha: 1.0)  // #6EE7B7
            })
        }
        static var primaryDark: Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.10, green: 0.65, blue: 0.48, alpha: 1.0)
                    : UIColor(red: 0.02, green: 0.59, blue: 0.41, alpha: 1.0)  // #059669
            })
        }

        // Secondary - Warm sunset orange
        static var accent: Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 1.0, green: 0.72, blue: 0.25, alpha: 1.0)
                    : UIColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1.0)  // #F59E0B
            })
        }
        static var accentLight: Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.50, green: 0.40, blue: 0.20, alpha: 1.0)
                    : UIColor(red: 0.99, green: 0.91, blue: 0.55, alpha: 1.0)  // #FDE68A
            })
        }
        static let purple = Color(hex: "8B5CF6")           // Friendly purple
        static let pink = Color(hex: "EC4899")             // Playful pink
        static let teal = Color(hex: "14B8A6")             // Soft teal
        static let mint = Color(hex: "34D399")             // Fresh mint

        // Fun additional colors for variety
        static let coral = Color(hex: "F87171")            // Soft coral
        static let lavender = Color(hex: "A78BFA")         // Gentle lavender
        static let sky = Color(hex: "38BDF8")              // Sky blue
        static let peach = Color(hex: "FDBA74")            // Warm peach
        static let rose = Color(hex: "FB7185")             // Soft rose

        // Legacy aliases (for compatibility)
        static var forest: Color { primary }
        static var forestLight: Color { primaryLight }
        static var forestMuted: Color { primaryLight }
        static var amber: Color { accent }
        static var amberLight: Color { accentLight }
        static let terracotta = coral
        static let terracottaLight = Color(hex: "FEE2E2")  // Light coral

        // Backgrounds - Warm and cozy (Dark mode adaptive)
        static var cream: Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0)  // Dark gray
                    : UIColor(red: 1.0, green: 0.98, blue: 0.92, alpha: 1.0)   // #FFFBEB
            })
        }
        static var ivory: Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)  // Darker
                    : UIColor(red: 1.0, green: 0.97, blue: 0.93, alpha: 1.0)   // #FEF7ED
            })
        }
        static var linen: Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.15, green: 0.15, blue: 0.16, alpha: 1.0)
                    : UIColor(red: 0.96, green: 0.94, blue: 0.91, alpha: 1.0)  // #F5F0E8
            })
        }

        // Neutrals - Warm grays (Dark mode adaptive)
        static var charcoal: Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)  // Light in dark mode
                    : UIColor(red: 0.12, green: 0.16, blue: 0.22, alpha: 1.0)  // #1F2937
            })
        }
        static var slate: Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.78, green: 0.80, blue: 0.82, alpha: 1.0)  // Lighter for dark mode readability
                    : UIColor(red: 0.25, green: 0.29, blue: 0.33, alpha: 1.0)  // #404854 - Darker for better contrast
            })
        }
        static var stone: Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.30, green: 0.32, blue: 0.35, alpha: 1.0)
                    : UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1.0)  // #D1D5DB
            })
        }
        static var mist: Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.18, green: 0.18, blue: 0.20, alpha: 1.0)
                    : UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)  // #F9FAFB
            })
        }

        // Semantic colors - Friendly and clear
        static var success: Color { primary }
        static var warning: Color { accent }
        static let danger = Color(hex: "EF4444")           // Soft red
        static let info = Color(hex: "3B82F6")             // Friendly blue

        // Attendance colors - Clear and friendly (Dark mode adaptive)
        static var presentBg: Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.06, green: 0.25, blue: 0.18, alpha: 1.0)
                    : UIColor(red: 0.82, green: 0.98, blue: 0.90, alpha: 1.0)  // #D1FAE5
            })
        }
        static var presentBorder: Color { primary }
        static var tardyBg: Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.30, green: 0.22, blue: 0.08, alpha: 1.0)
                    : UIColor(red: 1.0, green: 0.95, blue: 0.78, alpha: 1.0)   // #FEF3C7
            })
        }
        static var tardyBorder: Color { accent }
        static var absentBg: Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.30, green: 0.12, blue: 0.12, alpha: 1.0)
                    : UIColor(red: 1.0, green: 0.89, blue: 0.89, alpha: 1.0)   // #FEE2E2
            })
        }
        static let absentBorder = Color(hex: "EF4444")     // Soft red

        // Additional colors for variety
        static let indigo = Color(hex: "6366F1")           // Indigo
        static let cyan = Color(hex: "06B6D4")             // Cyan
        static let brown = Color(hex: "A16207")            // Warm brown
    }

    // MARK: - Typography (with Dynamic Type support)

    struct Typography {
        // Display - Bold rounded for headers (SF Rounded style)
        // Uses relativeTo for Dynamic Type scaling
        static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
            .system(size: size, weight: weight, design: .rounded)
        }

        // Headlines - Rounded sans-serif with Dynamic Type
        static func headline(_ size: CGFloat = 17, weight: Font.Weight = .semibold) -> Font {
            .system(size: size, weight: weight, design: .rounded)
        }

        // Body text - Clean default with Dynamic Type
        static func body(_ size: CGFloat = 15, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight, design: .default)
        }

        // Captions and labels with Dynamic Type
        static func caption(_ size: CGFloat = 12, weight: Font.Weight = .medium) -> Font {
            .system(size: size, weight: weight, design: .rounded)
        }

        // Monospace for numbers/data
        static func mono(_ size: CGFloat = 14, weight: Font.Weight = .medium) -> Font {
            .system(size: size, weight: weight, design: .monospaced)
        }

        // MARK: - Semantic Fonts (automatically scale with Dynamic Type)

        /// Large title for main headers - scales with accessibility settings
        static var largeTitle: Font { .largeTitle }

        /// Title for section headers
        static var title: Font { .title }

        /// Title2 for sub-sections
        static var title2: Font { .title2 }

        /// Title3 for card headers
        static var title3: Font { .title3 }

        /// Headline for emphasized content
        static var headlineSemantic: Font { .headline }

        /// Body text - primary content font
        static var bodySemantic: Font { .body }

        /// Callout for secondary content
        static var callout: Font { .callout }

        /// Subheadline for supporting text
        static var subheadline: Font { .subheadline }

        /// Footnote for small details
        static var footnote: Font { .footnote }

        /// Caption for labels and metadata
        static var captionSemantic: Font { .caption }

        /// Caption2 for smallest text
        static var caption2: Font { .caption2 }
    }

    // MARK: - Spacing

    struct Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }

    // MARK: - Corner Radius

    struct Radius {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
        static let full: CGFloat = 999
    }

    // MARK: - Shadows

    struct Shadows {
        static let subtle = Shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 2)
        static let soft = Shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 4)
        static let medium = Shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        static let elevated = Shadow(color: Color.black.opacity(0.20), radius: 30, x: 0, y: 15)

        // Colored shadows for vibrant accents
        static let forestGlow = Shadow(color: Colors.primary.opacity(0.35), radius: 12, x: 0, y: 6)
        static let amberGlow = Shadow(color: Colors.accent.opacity(0.35), radius: 10, x: 0, y: 4)
        static let successGlow = Shadow(color: Colors.success.opacity(0.35), radius: 10, x: 0, y: 4)
        static let dangerGlow = Shadow(color: Colors.danger.opacity(0.35), radius: 10, x: 0, y: 4)
    }

    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    // MARK: - Animation

    struct Animation {
        static let snappy = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let gentle = SwiftUI.Animation.easeOut(duration: 0.35)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)

        // Playful animations for light-hearted feel
        static let pop = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.6, blendDuration: 0)
        static let wiggle = SwiftUI.Animation.spring(response: 0.15, dampingFraction: 0.4)
        static let elastic = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.55)
        static let float = SwiftUI.Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions

extension View {
    // Apply theme shadow
    func themeShadow(_ shadow: Theme.Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }

    // Card style with cream background and subtle shadow
    func themeCard(padding: CGFloat = Theme.Spacing.md) -> some View {
        self
            .padding(padding)
            .background(Theme.Colors.cream)
            .cornerRadius(Theme.Radius.md)
            .themeShadow(Theme.Shadows.soft)
    }

    // Elevated card with more prominent shadow
    func themeElevatedCard(padding: CGFloat = Theme.Spacing.md) -> some View {
        self
            .padding(padding)
            .background(Color.white)
            .cornerRadius(Theme.Radius.lg)
            .themeShadow(Theme.Shadows.medium)
    }

    // Pulse animation for attention
    func pulse(_ isActive: Bool) -> some View {
        self
            .scaleEffect(isActive ? 1.02 : 1.0)
            .animation(isActive ? Theme.Animation.float : .default, value: isActive)
    }

    // Shake animation for errors
    func shake(_ isShaking: Bool) -> some View {
        self
            .offset(x: isShaking ? -5 : 0)
            .animation(
                isShaking
                    ? SwiftUI.Animation.linear(duration: 0.06).repeatCount(5, autoreverses: true)
                    : .default,
                value: isShaking
            )
    }

    // Press events for custom button interactions
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }

    // Entrance animation helper
    func fadeSlideIn(delay: Double = 0) -> some View {
        self
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .bottom)),
                removal: .opacity
            ))
    }
}

// MARK: - Playful Button Styles

/// Bouncy button style that scales down on press
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(Theme.Animation.pop, value: configuration.isPressed)
    }
}

/// Spring button style with slight rotation
struct PlayfulButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(Theme.Animation.elastic, value: configuration.isPressed)
    }
}

/// Card press style for interactive cards
struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(
                color: Color.black.opacity(configuration.isPressed ? 0.08 : 0.1),
                radius: configuration.isPressed ? 4 : 10,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .animation(Theme.Animation.snappy, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BounceButtonStyle {
    static var bounce: BounceButtonStyle { BounceButtonStyle() }
}

extension ButtonStyle where Self == PlayfulButtonStyle {
    static var playful: PlayfulButtonStyle { PlayfulButtonStyle() }
}

extension ButtonStyle where Self == CardPressStyle {
    static var cardPress: CardPressStyle { CardPressStyle() }
}

// MARK: - Reusable Components

/// Clean section header with rounded typography
struct ThemeSectionHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text(title)
                .font(Theme.Typography.headline(13, weight: .semibold))
                .foregroundColor(Theme.Colors.slate)
                .textCase(.uppercase)
                .tracking(0.8)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(Theme.Typography.caption(12))
                    .foregroundColor(Theme.Colors.stone)
            }
        }
    }
}

/// Vibrant primary button with macOS blue
struct ThemePrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(Theme.Typography.headline(15, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                LinearGradient(
                    colors: [Theme.Colors.primary, Theme.Colors.primaryDark],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(Theme.Radius.md)
            .themeShadow(Theme.Shadows.forestGlow)
        }
        .buttonStyle(.plain)
    }
}

/// Secondary button with light background
struct ThemeSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                }
                Text(title)
                    .font(Theme.Typography.headline(14, weight: .medium))
            }
            .foregroundColor(Theme.Colors.primary)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.xs)
            .background(Theme.Colors.primary.opacity(0.12))
            .cornerRadius(Theme.Radius.sm)
        }
        .buttonStyle(.plain)
    }
}

/// Bright empty state view
struct ThemeEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Decorative icon with vibrant gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.primaryLight.opacity(0.3), Theme.Colors.primary.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.primary.opacity(0.2), Theme.Colors.primaryDark.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 76, height: 76)

                Image(systemName: icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
            }
            .themeShadow(Theme.Shadows.forestGlow)

            VStack(spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(Theme.Typography.display(28))
                    .foregroundColor(Theme.Colors.charcoal)

                Text(message)
                    .font(Theme.Typography.body(15))
                    .foregroundColor(Theme.Colors.slate)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }

            if let actionTitle = actionTitle, let action = action {
                ThemePrimaryButton(actionTitle, icon: "plus.circle.fill", action: action)
                    .padding(.top, Theme.Spacing.sm)
            }
        }
    }
}

/// Refined list row with warm styling
struct ThemeListRow<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.vertical, Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.md)
            .background(Color.white)
            .cornerRadius(Theme.Radius.sm)
            .themeShadow(Theme.Shadows.subtle)
    }
}

// MARK: - Badge Styles

struct ThemeBadge: View {
    let text: String
    let style: BadgeStyle

    enum BadgeStyle {
        case primary, accent, purple, neutral, success, warning, danger

        // Legacy aliases
        static let forest = primary
        static let amber = accent
        static let terracotta = purple

        var backgroundColor: Color {
            switch self {
            case .primary: return Theme.Colors.primary.opacity(0.12)
            case .accent: return Theme.Colors.accent.opacity(0.15)
            case .purple: return Theme.Colors.purple.opacity(0.12)
            case .neutral: return Theme.Colors.mist
            case .success: return Theme.Colors.presentBg
            case .warning: return Theme.Colors.tardyBg
            case .danger: return Theme.Colors.absentBg
            }
        }

        var textColor: Color {
            switch self {
            case .primary: return Theme.Colors.primary
            case .accent: return Theme.Colors.accent
            case .purple: return Theme.Colors.purple
            case .neutral: return Theme.Colors.slate
            case .success: return Theme.Colors.success
            case .warning: return Theme.Colors.warning
            case .danger: return Theme.Colors.danger
            }
        }
    }

    var body: some View {
        Text(text)
            .font(Theme.Typography.caption(11, weight: .semibold))
            .foregroundColor(style.textColor)
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, Theme.Spacing.xxs)
            .background(style.backgroundColor)
            .cornerRadius(Theme.Radius.xs)
    }
}

// MARK: - Desk Styling for Seating Chart

struct ThemeDeskStyle {
    let backgroundColor: Color
    let borderColor: Color
    let shadowColor: Color
    let isOccupied: Bool

    static func standard(occupied: Bool) -> ThemeDeskStyle {
        if occupied {
            return ThemeDeskStyle(
                backgroundColor: Color.white,
                borderColor: Theme.Colors.primary.opacity(0.4),
                shadowColor: Theme.Colors.primary.opacity(0.15),
                isOccupied: true
            )
        } else {
            return ThemeDeskStyle(
                backgroundColor: Theme.Colors.ivory,
                borderColor: Theme.Colors.stone,
                shadowColor: Color.black.opacity(0.06),
                isOccupied: false
            )
        }
    }

    static func selected() -> ThemeDeskStyle {
        ThemeDeskStyle(
            backgroundColor: Theme.Colors.primary.opacity(0.1),
            borderColor: Theme.Colors.primary,
            shadowColor: Theme.Colors.primary.opacity(0.3),
            isOccupied: true
        )
    }

    static func attendance(_ status: AttendanceStatus) -> ThemeDeskStyle {
        switch status {
        case .present:
            return ThemeDeskStyle(
                backgroundColor: Theme.Colors.presentBg,
                borderColor: Theme.Colors.presentBorder,
                shadowColor: Theme.Colors.success.opacity(0.25),
                isOccupied: true
            )
        case .tardy:
            return ThemeDeskStyle(
                backgroundColor: Theme.Colors.tardyBg,
                borderColor: Theme.Colors.tardyBorder,
                shadowColor: Theme.Colors.warning.opacity(0.25),
                isOccupied: true
            )
        case .absent:
            return ThemeDeskStyle(
                backgroundColor: Theme.Colors.absentBg,
                borderColor: Theme.Colors.absentBorder,
                shadowColor: Theme.Colors.danger.opacity(0.25),
                isOccupied: true
            )
        }
    }
}

// MARK: - Preview

#Preview("Theme Components") {
    ScrollView {
        VStack(spacing: Theme.Spacing.xl) {
            // Empty state
            ThemeEmptyState(
                icon: "studentdesk",
                title: "Welcome",
                message: "Get started by creating your first class",
                actionTitle: "Create Class",
                action: {}
            )

            Divider()

            // Buttons
            VStack(spacing: Theme.Spacing.md) {
                ThemePrimaryButton("Primary Button", icon: "plus") {}
                ThemeSecondaryButton("Secondary Button", icon: "pencil") {}
            }

            Divider()

            // Badges
            HStack(spacing: Theme.Spacing.xs) {
                ThemeBadge(text: "Present", style: .success)
                ThemeBadge(text: "Tardy", style: .warning)
                ThemeBadge(text: "Absent", style: .danger)
                ThemeBadge(text: "5 students", style: .primary)
            }

            Divider()

            // Color swatches
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ThemeSectionHeader("Color Palette")

                HStack(spacing: Theme.Spacing.xs) {
                    colorSwatch(Theme.Colors.primary, "Blue")
                    colorSwatch(Theme.Colors.success, "Green")
                    colorSwatch(Theme.Colors.accent, "Orange")
                    colorSwatch(Theme.Colors.danger, "Red")
                    colorSwatch(Theme.Colors.purple, "Purple")
                }
            }

            Divider()

            // Section header
            ThemeSectionHeader("My Classes", subtitle: "Tap to view seating chart")
        }
        .padding()
    }
    .background(Theme.Colors.ivory)
}

private func colorSwatch(_ color: Color, _ name: String) -> some View {
    VStack(spacing: 4) {
        RoundedRectangle(cornerRadius: 8)
            .fill(color)
            .frame(width: 50, height: 50)
        Text(name)
            .font(.system(size: 10))
            .foregroundColor(Theme.Colors.slate)
    }
}
