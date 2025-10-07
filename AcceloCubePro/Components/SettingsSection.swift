//
//  SettingsSection.swift
//  AcceloCubePro
//
//  Created by Roy Dimapilis on 10/6/25.
//

import SwiftUI

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.teal)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                content
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal)
        }
    }
}

#Preview {
    SettingsSection(title: "Motion Control", icon: "slider.horizontal.3") {
        Text("Slider 1")
            .foregroundColor(.white)
        Text("Slider 2")
            .foregroundColor(.white)
    }
    .background(Color.black)
}
