//
//  TemplatePickerView.swift
//  SeatingChart
//
//  Created by GKWazy Software
//

import SwiftUI

struct TemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let selectedTemplate: (LayoutTemplate) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                    ForEach(LayoutTemplate.allCases) { template in
                        TemplateCard(template: template) {
                            selectedTemplate(template)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Template")
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

struct TemplateCard: View {
    let template: LayoutTemplate
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1))
                        .frame(height: 100)

                    Image(systemName: template.icon)
                        .font(.system(size: 40))
                        .foregroundColor(isSelected ? .blue : .blue.opacity(0.8))
                }

                // Title and description
                VStack(spacing: 4) {
                    Text(template.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TemplatePickerView(selectedTemplate: { _ in })
}
