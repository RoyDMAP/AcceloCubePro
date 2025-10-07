//
//  MotionSettings.swift
//  AcceloCubePro
//
//  Created by Roy Dimapilis on 10/6/25.
//

import SwiftUI

struct MotionSettingsView: View {
    @ObservedObject var vm: MotionVM
    
    var body: some View {
        SettingsSection(title: "Motion Control", icon: "slider.horizontal.3") {
            SliderControl(
                label: "Sample Rate",
                value: $vm.cfg.sampleHz,
                range: 10...120,
                step: 10,
                unit: "Hz",
                color: .teal,
                onChange: { vm.applySampleRate() }
            )
            
            SliderControl(
                label: "Smoothing",
                value: Binding(
                    get: { min(max(vm.cfg.smoothing, 0.0), 0.98) },
                    set: { vm.cfg.smoothing = min(max($0, 0.0), 0.98) }
                ),
                range: 0...0.98,
                step: 0.05,
                unit: "",
                color: .cyan,
                showDecimal: true
            )
            
            SliderControl(
                label: "Damping",
                value: $vm.cfg.damping,
                range: 0...0.1,
                step: 0.001,
                unit: "",
                color: .purple,
                showDecimal: true
            )
        }
    }
}
