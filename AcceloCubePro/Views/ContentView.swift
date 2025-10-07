//
//  ContentView.swift
//  AcceloCubePro
//
//  Created by Roy Dimapilis on 10/6/25.
//

import SwiftUI
import CoreMotion
import SceneKit

struct ContentView: View {
    @StateObject private var vm = MotionVM()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingResetConfirmation = false
    
    var body: some View {
        ZStack {
            // Dynamic gradient background
            LinearGradient(
                colors: [Color.black, Color(white: 0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HeaderView(
                        vm: vm,
                        authStatusText: authStatusText,
                        authStatusColor: authStatusColor
                    )
                    
                    // 3D Scene
                    SceneContainerView(vm: vm)
                    
                    // Primary Controls
                    PrimaryControlsView(
                        vm: vm,
                        showingResetConfirmation: $showingResetConfirmation
                    )
                    
                    // Motion Settings Section
                    MotionSettingsView(vm: vm)
                    
                    // Movement Limits Section
                    MovementLimitsView(vm: vm)
                    
                    // System Status
                    if vm.authorizationStatus != .authorized {
                        SystemStatusView(vm: vm)
                    }
                    
                    // Status message
                    Text(vm.status)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                }
            }
        }
        .confirmationDialog("Reset Position", isPresented: $showingResetConfirmation) {
            Button("Reset Position & Velocity", role: .destructive) {
                withAnimation(.spring(response: 0.3)) {
                    vm.recenter()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset the cube to center position with zero velocity")
        }
        .onAppear {
            vm.checkAuthorization()
        }
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .background:
                if vm.usingDeviceMotion {
                    vm.stop()
                }
            case .active:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !vm.usingDeviceMotion {
                        vm.start()
                    }
                }
            default:
                break
            }
        }
    }
    
    private var authStatusText: String {
        switch vm.authorizationStatus {
        case .authorized: return "Authorized"
        case .denied: return "Access Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Determined"
        @unknown default: return "Unknown"
        }
    }
    
    private var authStatusColor: Color {
        switch vm.authorizationStatus {
        case .authorized: return .green
        case .denied, .restricted: return .red
        case .notDetermined: return .yellow
        @unknown default: return .gray
        }
    }
    
    private func length(_ v: SIMD3<Float>) -> Float {
        sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
    }
}

#Preview {
    ContentView()
}
