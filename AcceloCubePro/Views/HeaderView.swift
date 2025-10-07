//
//  HeaderView.swift
//  AcceloCubePro
//
//  Created by Roy Dimapilis on 10/6/25.
//

import SwiftUI

struct HeaderView: View {
    @ObservedObject var vm: MotionVM
    let authStatusText: String
    let authStatusColor: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // App Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.teal, Color.cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "cube.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("AcceloCube Pro")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(authStatusColor)
                            .frame(width: 6, height: 6)
                        
                        Text(authStatusText)
                            .font(.caption)
                            .foregroundColor(authStatusColor)
                    }
                }
                
                Spacer()
            }
            
            // Status bar with metrics
            if vm.usingDeviceMotion {
                HStack(spacing: 16) {
                    MetricBadge(
                        icon: "speedometer",
                        value: String(format: "%.1f", length(vm.velocity)),
                        unit: "m/s",
                        color: .green
                    )
                    
                    MetricBadge(
                        icon: "timer",
                        value: String(format: "%.0f", vm.sampleLatencyMs),
                        unit: "ms",
                        color: .orange
                    )
                    
                    MetricBadge(
                        icon: "waveform.path.ecg",
                        value: "\(Int(vm.cfg.sampleHz))",
                        unit: "Hz",
                        color: .cyan
                    )
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        )
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private func length(_ v: SIMD3<Float>) -> Float {
        sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
    }
}
