//
//  IconButton.swift
//  habit-tracker
//
//  Created by Ivan Kharitonenko on 31/10/2025.
//

import SwiftUI

// MARK: - Icon button

struct IconButton: View {
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSelected ? AnyShapeStyle(color.gradient) : AnyShapeStyle(Color.primary.opacity(0.06)))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(isSelected ? AnyShapeStyle(Color.white) : AnyShapeStyle(color))
                }
                .shadow(color: isSelected ? color.opacity(0.45) : .clear, radius: 8, y: 4)
                .scaleEffect(isSelected ? 1.08 : 1)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        .accessibilityLabel(icon.replacingOccurrences(of: ".", with: " "))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Color button

struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color.gradient)
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    if isSelected {
                        Circle().strokeBorder(.white, lineWidth: 3).padding(3)
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                }
                .shadow(color: color.opacity(isSelected ? 0.6 : 0.2), radius: isSelected ? 10 : 4, y: 3)
                .scaleEffect(isSelected ? 1.12 : 1)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
