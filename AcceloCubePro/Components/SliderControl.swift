//
//  SliderControl.swift
//  AcceloCubePro
//
//  Created by Roy Dimapilis on 10/6/25.
//

import SwiftUI

struct SliderControl: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let color: Color
    var showDecimal: Bool = false
    var onChange: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Spacer()
                Text(formatValue())
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(color.opacity(0.2))
                    )
            }
            
            Slider(value: $value, in: range, step: step)
                .tint(color)
                .onChange(of: value) {
                    onChange?()
                }
        }
    }
    
    private func formatValue() -> String {
        if showDecimal {
            return String(format: "%.2f", value) + (unit.isEmpty ? "" : " \(unit)")
        } else {
            return "\(Int(value))" + (unit.isEmpty ? "" : " \(unit)")
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SliderControl(
            label: "Sample Rate",
            value: .constant(60),
            range: 10...120,
            step: 10,
            unit: "Hz",
            color: .teal
        )
        
        SliderControl(
            label: "Smoothing",
            value: .constant(0.2),
            range: 0...0.98,
            step: 0.05,
            unit: "",
            color: .cyan,
            showDecimal: true
        )
    }
    .padding()
    .background(Color.black)
}
