//
//  SceneContainer.swift
//  AcceloCubePro
//
//  Created by Roy Dimapilis on 10/6/25.
//

import SwiftUI
import SceneKit

struct SceneContainerView: View {
    @ObservedObject var vm: MotionVM
    
    var body: some View {
        VStack(spacing: 0) {
            SceneViewBridge(vm: vm)
                .frame(height: 340)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.teal.opacity(0.5), Color.cyan.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
            
            // Position display
            HStack(spacing: 20) {
                AxisDisplay(label: "X", value: vm.pos.x, color: .red)
                AxisDisplay(label: "Y", value: vm.pos.y, color: .green)
                AxisDisplay(label: "Z", value: vm.pos.z, color: .blue)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal)
            .offset(y: -12)
        }
    }
}
