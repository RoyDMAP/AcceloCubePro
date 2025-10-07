//
//  MotionKit.swift
//  AcceloCubePro
//
//  Created by Roy Dimapilis on 10/6/25.
//

import Foundation
import SceneKit
import CoreMotion
import SwiftUI
import simd
import Combine
import QuartzCore

struct MotionConfig {
    var sampleHz: Double = 60
    var smoothing: Double = 0.3
    var damping: Double = 0.08  // Increased to 8% for more stability
    var maxSpeed: Double = 1.5  // Reduced further
    var maxRange: Double = 0.8  // Tighter boundary
    var loggingEnabled: Bool = false
    var hapticsEnabled: Bool = true  // Stretch Goal 2
    var showTrails: Bool = false      // Stretch Goal 1
}

@MainActor
final class MotionVM: ObservableObject {
    @Published var cfg = MotionConfig()
    @Published var quat: simd_quatf = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
    @Published var pos: SIMD3<Float> = .zero
    @Published var status: String = "Idle"
    @Published var sampleLatencyMs: Double = 0
    @Published var usingDeviceMotion: Bool = false
    @Published var authorizationStatus: CMAuthorizationStatus = .notDetermined
    @Published var positionTrail: [SIMD3<Float>] = []  // Stretch Goal 1
    @Published var velocity: SIMD3<Float> = .zero
    
    let mgr = CMMotionManager()
    
    private let queue = OperationQueue()
    private var v: SIMD3<Float> = .zero
    private var lastTimestamp: Double?
    private var neutralInv: simd_quatf = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
    private var logger: CSVLogger? = nil
    private var saturationHapticTimer: Date = .distantPast
    
    // High-pass filter state
    private var lpAccel: SIMD3<Float> = .zero
    private let hpAlpha: Float = 0.9

    init() {
        queue.name = "MotionVM.queue"
        queue.qualityOfService = .userInteractive
        checkAuthorization()
    }
    
    func checkAuthorization() {
        #if os(iOS)
        if #available(iOS 11.0, *) {
            authorizationStatus = CMMotionActivityManager.authorizationStatus()
            
            switch authorizationStatus {
            case .authorized:
                status = "Motion authorized"
            case .denied:
                status = "Motion access denied - enable in Settings"
            case .restricted:
                status = "Motion access restricted"
            case .notDetermined:
                status = "Motion access not determined - starting will request permission"
            @unknown default:
                status = "Unknown authorization status"
            }
        } else {
            // assume authorized
            authorizationStatus = .authorized
            status = "Ready"
        }
        #else
        authorizationStatus = .authorized
        status = "Ready"
        #endif
    }

    func start() {
        guard mgr.isDeviceMotionAvailable else {
            status = "DeviceMotion unavailable"
            usingDeviceMotion = false
            return
        }
        
        // Check authorization
        checkAuthorization()
        #if os(iOS)
        if #available(iOS 11.0, *) {
            if authorizationStatus == .denied || authorizationStatus == .restricted {
                status = "Cannot start - motion access denied"
                return
            }
        }
        #endif
        
        stop()
        usingDeviceMotion = true
        mgr.deviceMotionUpdateInterval = 1.0 / max(1.0, cfg.sampleHz)
        lastTimestamp = nil
        v = .zero
        lpAccel = .zero
        positionTrail.removeAll()
        status = "Starting..."

        if cfg.loggingEnabled {
            logger = CSVLogger(filename: "accelocube_log.csv")
            logger?.writeHeaderIfNeeded()
        } else {
            logger = nil
        }

        mgr.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] dm, err in
            guard let self = self else { return }
            if let err = err {
                Task { @MainActor in
                    self.status = "Error: \(err.localizedDescription)"
                    self.usingDeviceMotion = false
                }
                return
            }
            guard let dm = dm else { return }

            let now = CACurrentMediaTime()
            let ts = dm.timestamp
            
            // Calculate sensor latency
            let sensorLatencyMs = (now - ts) * 1000.0
            
            let dt: Double
            if let last = self.lastTimestamp {
                dt = max(0, min(ts - last, 1.0))
            } else {
                dt = 0
            }
            self.lastTimestamp = ts

            // Read quaternion from attitude
            let aq = dm.attitude.quaternion
            var q = simd_quatf(ix: Float(aq.x), iy: Float(aq.y), iz: Float(aq.z), r: Float(aq.w))
            q = self.neutralInv * q

            // Read userAcceleration
            let ua = SIMD3<Float>(Float(dm.userAcceleration.x),
                                  Float(dm.userAcceleration.y),
                                  Float(dm.userAcceleration.z))
            
            self.lpAccel = self.lpAccel * self.hpAlpha + ua * (1.0 - self.hpAlpha)
            let hpAccel = ua - self.lpAccel

            // world coordinates
            let qWorld = self.neutralInv.inverse * q
            let aWorld = qWorld.act(hpAccel) * 9.81

            // Velocity integration with damping
            var vNew = self.v + aWorld * Float(dt)
            if !vNew.allFinite { vNew = .zero }
            
            let speed = length(vNew)
            var didSaturate = false
            
            // Clamp velocity to maxSpeed
            if speed > Float(self.cfg.maxSpeed) {
                vNew = normalize(vNew) * Float(self.cfg.maxSpeed)
                didSaturate = true
            }
            
            vNew *= max(0, 1.0 - Float(self.cfg.damping))

            // Position integration
            var pNew = self.pos + vNew * Float(dt)
        
            let prevPos = pNew
            pNew = simd_clamp(pNew,
                              SIMD3<Float>(repeating: -Float(self.cfg.maxRange)),
                              SIMD3<Float>(repeating: Float(self.cfg.maxRange)))
            
            if pNew != prevPos {
                didSaturate = true
            }
            
            // Auto-recenter if cube gets too far
            let distanceFromOrigin = length(pNew)
            if distanceFromOrigin > Float(self.cfg.maxRange) * 0.9 {
                // Cube is near boundary, apply strong damping
                vNew *= 0.5
            }

            // Smoothing via SLERP
            let alpha = Float(min(max(self.cfg.smoothing, 0.0), 0.98))
            let qSmoothed = simd_slerp(self.quat, q, 1 - alpha)

            Task { @MainActor in
                self.quat = qSmoothed
                self.v = vNew
                self.velocity = vNew
                self.pos = pNew
                self.sampleLatencyMs = sensorLatencyMs
                self.status = "OK \(Int(self.cfg.sampleHz)) Hz | v=\(String(format: "%.2f", length(vNew))) m/s | latency=\(String(format: "%.1f", sensorLatencyMs))ms"
                
                // Stretch Goal 1: Position trails
                if self.cfg.showTrails {
                    self.positionTrail.append(pNew)
                    if self.positionTrail.count > 50 {
                        self.positionTrail.removeFirst()
                    }
                }
                
                // Stretch Goal 2, Haptic feedback on saturation
                if didSaturate && self.cfg.hapticsEnabled {
                    let now = Date()
                    if now.timeIntervalSince(self.saturationHapticTimer) > 0.5 {
                        self.triggerHapticFeedback()
                        self.saturationHapticTimer = now
                    }
                }
            }

            if let logger = self.logger, dt > 0 {
                logger.writeRow(timestamp: ts, q: qSmoothed, userAccel: ua, pos: pNew)
            }
        }
        
        // Re-check authorization
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkAuthorization()
        }
    }

    func stop() {
        if mgr.isDeviceMotionActive {
            mgr.stopDeviceMotionUpdates()
            usingDeviceMotion = false
            status = "Stopped"
        }
        positionTrail.removeAll()
    }

    func toggle() { usingDeviceMotion ? stop() : start() }

    func recenter() {
        v = .zero
        velocity = .zero
        pos = .zero
        lpAccel = .zero
        positionTrail.removeAll()
        status = "Recentered"
    }

    func calibrateNeutral(currentAttitude: CMQuaternion?) {
        guard let cq = currentAttitude else { return }
        let q = simd_quatf(ix: Float(cq.x), iy: Float(cq.y), iz: Float(cq.z), r: Float(cq.w))
        neutralInv = q.inverse
        status = "Calibrated to current orientation"
    }

    func applySampleRate() {
        if usingDeviceMotion { start() }
    }
    
    // Stretch Goal 2: Haptic feedback
    private func triggerHapticFeedback() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }

    private func formatVec(_ v: SIMD3<Float>) -> String {
        String(format: "%.2f, %.2f, %.2f", v.x, v.y, v.z)
    }
}

private extension SIMD3 where Scalar == Float {
    var allFinite: Bool { x.isFinite && y.isFinite && z.isFinite }
}

final class CSVLogger {
    private let url: URL
    private var wroteHeader = false
    private let fm = FileManager.default

    init?(filename: String) {
        do {
            let docs = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            url = docs.appendingPathComponent(filename)
        } catch { return nil }
    }

    func writeHeaderIfNeeded() {
        guard wroteHeader == false else { return }
        let header = "timestamp,qx,qy,qz,qw,ax,ay,az,px,py,pz\n"
        append(text: header)
        wroteHeader = true
    }

    func writeRow(timestamp: Double, q: simd_quatf, userAccel: SIMD3<Float>, pos: SIMD3<Float>) {
        let row = String(format: "%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
                         timestamp, q.imag.x, q.imag.y, q.imag.z, q.real,
                         userAccel.x, userAccel.y, userAccel.z, pos.x, pos.y, pos.z)
        append(text: row)
    }

    private func append(text: String) {
        guard let data = text.data(using: .utf8) else { return }
        if FileManager.default.fileExists(atPath: url.path) {
            if let handle = try? FileHandle(forUpdating: url) {
                defer { try? handle.close() }
                _ = try? handle.seekToEnd()
                _ = try? handle.write(contentsOf: data)
            }
        } else {
            _ = try? data.write(to: url)
        }
    }
}

struct SceneViewBridge: UIViewRepresentable {
    @ObservedObject var vm: MotionVM

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = makeScene()
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = false
        view.backgroundColor = .black
        context.coordinator.cubeNode = view.scene?.rootNode.childNode(withName: "cube", recursively: false)
        context.coordinator.cameraNode = view.scene?.rootNode.childNode(withName: "camera", recursively: true)
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        guard let cube = context.coordinator.cubeNode else { return }
        let q = vm.quat
        cube.orientation = SCNQuaternion(q.imag.x, q.imag.y, q.imag.z, q.real)
        cube.position = SCNVector3(vm.pos.x, vm.pos.y, vm.pos.z)
        
        // Stretch Goal 1: Update trail geometry
        if vm.cfg.showTrails && !vm.positionTrail.isEmpty {
            context.coordinator.updateTrail(positions: vm.positionTrail, in: view.scene!)
        } else {
            context.coordinator.clearTrail(in: view.scene!)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var cubeNode: SCNNode?
        var cameraNode: SCNNode?
        var trailNode: SCNNode?
        
        func updateTrail(positions: [SIMD3<Float>], in scene: SCNScene) {
            // Remove old trail
            trailNode?.removeFromParentNode()
            
            guard positions.count >= 2 else { return }
            
            // Create line geometry from positions
            var vertices: [SCNVector3] = []
            var indices: [Int32] = []
            
            for (i, pos) in positions.enumerated() {
                vertices.append(SCNVector3(pos.x, pos.y, pos.z))
                if i > 0 {
                    indices.append(Int32(i - 1))
                    indices.append(Int32(i))
                }
            }
            
            let vertexSource = SCNGeometrySource(vertices: vertices)
            let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<Int32>.size)
            let element = SCNGeometryElement(data: indexData,
                                            primitiveType: .line,
                                            primitiveCount: indices.count / 2,
                                            bytesPerIndex: MemoryLayout<Int32>.size)
            
            let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
            
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.systemTeal.withAlphaComponent(0.5)
            material.emission.contents = UIColor.systemTeal.withAlphaComponent(0.3)
            geometry.materials = [material]
            
            let node = SCNNode(geometry: geometry)
            scene.rootNode.addChildNode(node)
            trailNode = node
        }
        
        func clearTrail(in scene: SCNScene) {
            trailNode?.removeFromParentNode()
            trailNode = nil
        }
    }

    private func makeScene() -> SCNScene {
        let scene = SCNScene()

        // Ground grid
        let floor = SCNFloor()
        floor.firstMaterial?.diffuse.contents = UIColor(white: 0.1, alpha: 1)
        floor.firstMaterial?.roughness.contents = 0.8
        let floorNode = SCNNode(geometry: floor)
        scene.rootNode.addChildNode(floorNode)
        
        // made the cube larger
        let box = SCNBox(width: 0.35, height: 0.35, length: 0.35, chamferRadius: 0.03)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor.systemTeal
        mat.roughness.contents = 0.4
        mat.metalness.contents = 0.2
        box.materials = [mat]
        let cubeNode = SCNNode(geometry: box)
        cubeNode.name = "cube"
        cubeNode.position = SCNVector3(0, 0.2, 0)
        scene.rootNode.addChildNode(cubeNode)

        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 200
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)

        let directional = SCNLight()
        directional.type = .directional
        directional.intensity = 700
        let dirNode = SCNNode()
        dirNode.light = directional
        dirNode.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 4, 0)
        scene.rootNode.addChildNode(dirNode)

        let camera = SCNCamera()
        camera.zNear = 0.01
        camera.zFar = 100
        camera.wantsHDR = true
        camera.fieldOfView = 60  // Wider field of view
        let camNode = SCNNode()
        camNode.name = "camera"
        camNode.camera = camera
        camNode.position = SCNVector3(0, 0.8, 3.5)  // Moved back and up
        camNode.look(at: SCNVector3(0, 0.15, 0))
        scene.rootNode.addChildNode(camNode)

        return scene
    }
}

#Preview {
    SceneViewBridge(vm: MotionVM())
        .frame(width: 300, height: 400)
        .background(Color.black)
}
