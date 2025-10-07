//
//  AxisDisplay.swift
//  AcceloCubePro
//
//  Created by Roy Dimapilis on 10/6/25.
//

import SwiftUI

struct AxisDisplay: View {
    let label: String
    let value: Float
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(String(format: "%.2f", value))
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
                .foregroundColor(.white)
            Text("meters")
                .font(.system(size: 8))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HStack(spacing: 20) {
        AxisDisplay(label: "X", value: 1.25, color: .red)
        AxisDisplay(label: "Y", value: -0.50, color: .green)
        AxisDisplay(label: "Z", value: 0.75, color: .blue)
    }
    .padding()
    .background(Color.black)
}
