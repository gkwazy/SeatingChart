//
//  NumberInputStepper.swift
//  SeatingChart
//
//  A stepper that allows both tapping to type a value and using +/- buttons
//  Long-press on +/- buttons to increment faster
//

import SwiftUI

struct NumberInputStepper: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    @State private var textValue: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var timer: Timer?
    @State private var isLongPressing = false

    var body: some View {
        HStack {
            Text(label)

            Spacer()

            HStack(spacing: 0) {
                // Minus button with long-press support
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(value <= range.lowerBound ? .gray : .blue)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemGray5))
                    .cornerRadius(8, corners: [.topLeft, .bottomLeft])
                    .contentShape(Rectangle())
                    .onTapGesture {
                        decrementValue(by: 1)
                    }
                    .onLongPressGesture(minimumDuration: 0.3, pressing: { pressing in
                        if pressing {
                            startDecrementing()
                        } else {
                            stopTimer()
                        }
                    }, perform: {})

                // Editable text field - wider to fit larger numbers
                TextField("", text: $textValue)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 70, height: 44)
                    .background(Color(.systemGray6))
                    .focused($isTextFieldFocused)
                    .onChange(of: textValue) { _, newValue in
                        // Filter non-numeric characters
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            textValue = filtered
                        }
                    }
                    .onSubmit {
                        commitTextValue()
                    }
                    .onChange(of: isTextFieldFocused) { _, focused in
                        if !focused {
                            commitTextValue()
                        }
                    }

                // Plus button with long-press support
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(value >= range.upperBound ? .gray : .blue)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemGray5))
                    .cornerRadius(8, corners: [.topRight, .bottomRight])
                    .contentShape(Rectangle())
                    .onTapGesture {
                        incrementValue(by: 1)
                    }
                    .onLongPressGesture(minimumDuration: 0.3, pressing: { pressing in
                        if pressing {
                            startIncrementing()
                        } else {
                            stopTimer()
                        }
                    }, perform: {})
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .onAppear {
            textValue = "\(value)"
        }
        .onChange(of: value) { _, newValue in
            if !isTextFieldFocused {
                textValue = "\(newValue)"
            }
        }
        .onDisappear {
            stopTimer()
        }
    }

    private func incrementValue(by amount: Int) {
        let newValue = min(value + amount, range.upperBound)
        if newValue != value {
            value = newValue
            textValue = "\(value)"
        }
    }

    private func decrementValue(by amount: Int) {
        let newValue = max(value - amount, range.lowerBound)
        if newValue != value {
            value = newValue
            textValue = "\(value)"
        }
    }

    private func startIncrementing() {
        isLongPressing = true
        var tickCount = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            tickCount += 1
            // Speed up the increment rate over time
            let increment: Int
            if tickCount > 50 {
                increment = 100 // Very fast after 5 seconds
            } else if tickCount > 20 {
                increment = 10  // Faster after 2 seconds
            } else {
                increment = 1   // Normal speed
            }
            incrementValue(by: increment)
        }
    }

    private func startDecrementing() {
        isLongPressing = true
        var tickCount = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            tickCount += 1
            // Speed up the decrement rate over time
            let decrement: Int
            if tickCount > 50 {
                decrement = 100 // Very fast after 5 seconds
            } else if tickCount > 20 {
                decrement = 10  // Faster after 2 seconds
            } else {
                decrement = 1   // Normal speed
            }
            decrementValue(by: decrement)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isLongPressing = false
    }

    private func commitTextValue() {
        if let intValue = Int(textValue) {
            // Clamp to range
            value = min(max(intValue, range.lowerBound), range.upperBound)
        }
        textValue = "\(value)"
    }
}

// Helper extension for corner radius on specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var value = 5

        var body: some View {
            Form {
                NumberInputStepper(label: "Rows", value: $value, range: 1...100)
                NumberInputStepper(label: "Total Desks", value: $value, range: 1...1000)
            }
        }
    }

    return PreviewWrapper()
}
