//
//  PrimaryControls.swift
//  AcceloCubePro
//
//  Created by Roy Dimapilis on 10/6/25.
//

import SwiftUI
import CoreMotion

struct PrimaryControlsView: View {
    @ObservedObject var vm: MotionVM
    @Binding var showingResetConfirmation: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ControlButton(
                icon: vm.usingDeviceMotion ? "pause.fill" : "play.fill",
                label: vm.usingDeviceMotion ? "Stop" : "Start",
                color: vm.usingDeviceMotion ? .red : .green,
                action: {
                    withAnimation(.spring(response: 0.3)) {
                        vm.toggle()
                    }
                }
            )
            
            ControlButton(
                icon: "arrow.clockwise",
                label: "Reset",
                color: .blue,
                action: {
                    showingResetConfirmation = true
                }
            )
            
            ControlButton(
                icon: "scope",
                label: "Calibrate",
                color: .orange,
                action: {
                    if let attitude = vm.mgr.deviceMotion?.attitude {
                        vm.calibrateNeutral(currentAttitude: attitude.quaternion)
                    }
                }
            )
        }
        .padding(.horizontal)
    }
}
