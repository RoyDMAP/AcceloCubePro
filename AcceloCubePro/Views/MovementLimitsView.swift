//
//  MovementLimitsView.swift
//  AcceloCubePro
//
//  Created by Roy Dimapilis on 10/6/25.
//

import SwiftUI

struct MovementLimitsView: View {
    @ObservedObject var vm: MotionVM
    
    var body: some View {
        SettingsSection(title: "Movement Limits", icon: "scope") {
            SliderControl(
                label: "Max Speed",
                value: $vm.cfg.maxSpeed,
                range: 1...20,
                step: 0.5,
                unit: "m/s",
                color: .orange
            )
            
            SliderControl(
                label: "Max Range",
                value: $vm.cfg.maxRange,
                range: 0.5...10,
                step: 0.5,
                unit: "m",
                color: .red
            )
        }
    }
}
