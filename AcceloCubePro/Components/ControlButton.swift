//
//  ControlButton.swift
//  AcceloCubePro
//
//  Created by Roy Dimapilis on 10/6/25.
//

import SwiftUI

struct ControlButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: color.opacity(0.4), radius: 8, y: 4)
            )
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        ControlButton(icon: "play.fill", label: "Start", color: .green, action: {})
        ControlButton(icon: "arrow.clockwise", label: "Reset", color: .blue, action: {})
        ControlButton(icon: "scope", label: "Calibrate", color: .orange, action: {})
    }
    .padding()
    .background(Color.black)
}
