//
//  DeskTypePickerView.swift
//  SeatingChart
//
//  Created by Claude
//

import SwiftUI

struct DeskTypePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let selectedType: (DeskType) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 16) {
                    ForEach(DeskType.allCases) { type in
                        DeskTypeCard(type: type) {
                            selectedType(type)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Add Desk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DeskTypeCard: View {
    let type: DeskType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Preview of desk shape
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .frame(height: 100)

                    DeskShape(desk: Desk(type: type))
                        .scaleEffect(0.6)
                }

                // Info
                VStack(spacing: 4) {
                    Text(type.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text("Seats \(type.defaultCapacity)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DeskTypePickerView(selectedType: { _ in })
}
