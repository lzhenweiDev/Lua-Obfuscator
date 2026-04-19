//
//  PresetButton.swift
//  Lua Obfuscator
//
//  Created by Zhenwei on 19.04.26.
//


import SwiftUI

struct PresetButton: View {
    let preset: ContentView.Preset
    let isSelected: Bool
    let action: () -> Void
    
    var presetDescription: String {
        switch preset {
        case .minify: return "Compress only"
        case .weak: return "Light protection"
        case .medium: return "Recommended"
        case .strong: return "Strong protection"
        case .maximum: return "Maximum protection"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: preset.icon)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.rawValue)
                        .font(.body)
                    Text(presetDescription)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.white)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary.opacity(0.5))
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
    }
}
