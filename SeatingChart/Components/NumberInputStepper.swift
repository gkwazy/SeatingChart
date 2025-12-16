//
//  NumberInputStepper.swift
//  SeatingChart
//
//  A stepper that allows both tapping to type a value and using +/- buttons
//

import SwiftUI

struct NumberInputStepper: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    @State private var textValue: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        HStack {
            Text(label)

            Spacer()

            HStack(spacing: 0) {
                // Minus button
                Button {
                    if value > range.lowerBound {
                        value -= 1
                        textValue = "\(value)"
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(value <= range.lowerBound ? .gray : .blue)
                        .frame(width: 36, height: 36)
                        .background(Color(.systemGray5))
                        .cornerRadius(8, corners: [.topLeft, .bottomLeft])
                }
                .disabled(value <= range.lowerBound)

                // Editable text field
                TextField("", text: $textValue)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 50, height: 36)
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

                // Plus button
                Button {
                    if value < range.upperBound {
                        value += 1
                        textValue = "\(value)"
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(value >= range.upperBound ? .gray : .blue)
                        .frame(width: 36, height: 36)
                        .background(Color(.systemGray5))
                        .cornerRadius(8, corners: [.topRight, .bottomRight])
                }
                .disabled(value >= range.upperBound)
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
                NumberInputStepper(label: "Rows", value: $value, range: 1...15)
                NumberInputStepper(label: "Columns", value: $value, range: 1...15)
            }
        }
    }

    return PreviewWrapper()
}
