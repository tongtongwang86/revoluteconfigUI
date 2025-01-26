//
//  identvisual.swift
//  revoluteconfigUI
//
//  Created by Tong tong wang on 29/07/2024.
//
//
//  identvisual.swift
//  revoluteconfigUI
//
//  Created by Tong tong wang on 29/07/2024.
//

import Foundation
import SwiftUI
import SceneKit


struct identviewa: View {
    @Binding var numberOfCapsulesInt: Int
    var numberOfCapsulesDouble: Double {
        Double(numberOfCapsulesInt)
    }
    @Binding var showTorusAndCapsules: Bool
    @Binding var capRotationY: Float  // State variable for y-rotation of cap

    var body: some View {
        
            SceneKitView(numberOfCapsules: Int(numberOfCapsulesDouble), showTorusAndCapsules: $showTorusAndCapsules, capRotationY: $capRotationY)
                
                .background(Color.clear)
                .frame(maxWidth: UIScreen.screenWidth, maxHeight: UIScreen.screenWidth)
                .background(WindowBackgroundColorView())
                .edgesIgnoringSafeArea(.top)
            
        
    }
}

struct SceneKitView: UIViewRepresentable {
    var numberOfCapsules: Int
    @Binding var showTorusAndCapsules: Bool
    @Binding var capRotationY: Float // Binding for y-rotation of cap

    class Coordinator: NSObject {
        var parent: SceneKitView
        var capsuleNodes: [SCNNode] = []
        var torusNode: SCNNode?
        var capNode: SCNNode?

        init(parent: SceneKitView) {
            self.parent = parent
        }

        func updateVisibility() {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.2 // Adjust animation duration as needed
            let targetOpacity: CGFloat = parent.showTorusAndCapsules ? 1.0 : 0.0
            torusNode?.opacity = targetOpacity
            for node in capsuleNodes {
                node.opacity = targetOpacity
            }
            SCNTransaction.commit()
        }

        func updateCapsules(numberOfCapsules: Int, scene: SCNScene) {
            DispatchQueue.global(qos: .userInitiated).async {
                let radius: Float = 1.5
                let angleIncrement = self.degreesToRadians(360.0 / Float(numberOfCapsules))
                
                DispatchQueue.main.async {
                    SCNTransaction.animationDuration = 0.3

                    // Remove excess capsules without using SCNTransaction to avoid stutter
                    while self.capsuleNodes.count > numberOfCapsules {
                        if let node = self.capsuleNodes.popLast() {
                            node.removeFromParentNode()
                        }
                    }
                    
                    // Add or update capsules in batch
                    for i in 0..<numberOfCapsules {
                        let targetAngle = angleIncrement * Float(i)
                        let x = radius * cos(targetAngle)
                        let z = radius * sin(targetAngle)

                        if i < self.capsuleNodes.count {
                            // Update existing capsule with smooth transition
                            let capsuleNode = self.capsuleNodes[i]
                            let startAngle = atan2(capsuleNode.position.z, capsuleNode.position.x)
                            var angleDifference = targetAngle - startAngle
                            
                            if abs(angleDifference) > .pi {
                                angleDifference -= (2 * .pi) * (angleDifference > 0 ? 1 : -1)
                            }

                            // Animate position with ease-out
                            let action = SCNAction.customAction(duration: 0.3) { node, time in
                                let t = time / 0.3
                                let easeOutT = 1 - pow(1 - t, 3)
                                let currentAngle = startAngle + angleDifference * Float(easeOutT)
                                let newX = radius * cos(currentAngle)
                                let newZ = radius * sin(currentAngle)
                                capsuleNode.position = SCNVector3(x: newX, y: 0.5, z: newZ)
                            }
                            capsuleNode.runAction(action)
                        } else {
                            // Reuse or create new capsule as needed
                            let capsuleNode = SCNNode()
                            let capsulePositionNode = SCNNode()
                            let material = SCNMaterial()
                            
                            material.emission.contents = UIColor.white
                            capsuleNode.geometry = SCNCapsule(capRadius: 0.01, height: 0.2)
                            capsuleNode.eulerAngles = SCNVector3(x: self.degreesToRadians(90), y: 0, z: 0)
                            capsuleNode.geometry?.materials = [material]
                            
                            capsulePositionNode.addChildNode(capsuleNode)
                            capsulePositionNode.position = SCNVector3(x: x, y: 0.5, z: z)
                            capsulePositionNode.eulerAngles = SCNVector3(x: 0, y: 0, z: self.degreesToRadians(90))

                            let nodeLookAt = SCNNode()
                            nodeLookAt.position = SCNVector3(x: 0, y: 0.5, z: 0)
                            scene.rootNode.addChildNode(nodeLookAt)

                            let lookAtOrigin = SCNLookAtConstraint(target: nodeLookAt)
                            capsulePositionNode.constraints = [lookAtOrigin]

                            scene.rootNode.addChildNode(capsulePositionNode)
                            self.capsuleNodes.append(capsulePositionNode)
                        }
                    }

                    DispatchQueue.main.async {
                        self.updateVisibility()
                    }
                }
            }
        }


        func updateCapRotation() {
            guard let capNode = self.capNode else { return }
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            capNode.eulerAngles.y = degreesToRadians(parent.capRotationY)
            SCNTransaction.commit()
        }

        func degreesToRadians(_ degrees: Float) -> Float {
            return degrees * .pi / 180
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.showsStatistics = true
        sceneView.backgroundColor = .clear // Set background color to clear
        
        if let gestureRecognizers = sceneView.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if let tapRecognizer = recognizer as? UITapGestureRecognizer, tapRecognizer.numberOfTapsRequired == 2 {
                    tapRecognizer.isEnabled = false
                } else if let rotationRecognizer = recognizer as? UIRotationGestureRecognizer {
                    rotationRecognizer.isEnabled = false
                } else if let panRecognizer = recognizer as? UIPanGestureRecognizer {
                    panRecognizer.maximumNumberOfTouches = 1
                }
            }
        }
        
        
        // Create the scene
        let scene = SCNScene()
        
        if let baseScene = SCNScene(named: "base.usdz") {
            let baseNode = baseScene.rootNode.clone()
            baseNode.name = "base"
            scene.rootNode.addChildNode(baseNode)
        }
        
        if let capScene = SCNScene(named: "cap.usdz") {
            let capNode = capScene.rootNode.clone()
            capNode.name = "cap"
            scene.rootNode.addChildNode(capNode)
        }

        // Create a camera node
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.fieldOfView = 20
        cameraNode.camera = camera
//        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        cameraNode.position = SCNVector3(x: 4, y: 5, z: 10)
        cameraNode.eulerAngles = SCNVector3(x: degreesToRadians(27), y: 0, z: 0)
        
        let lookAtOrigin = SCNLookAtConstraint(target: scene.rootNode)
        cameraNode.constraints = [lookAtOrigin]
        
        scene.rootNode.addChildNode(cameraNode)

        // Create the torus node
        let material = SCNMaterial()
        material.emission.contents = UIColor.blue
        material.transparency = 0.2
        
        let torus = SCNNode()
        torus.geometry = SCNTorus(ringRadius: 1.5, pipeRadius: 0.01)
        
        torus.geometry?.materials = [material]
        torus.position = SCNVector3(x: 0, y: 0.5, z: 0)
        scene.rootNode.addChildNode(torus)
        context.coordinator.torusNode = torus

        sceneView.scene = scene
        context.coordinator.updateCapsules(numberOfCapsules: numberOfCapsules, scene: scene)
        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        if let capNode = uiView.scene?.rootNode.childNode(withName: "cap", recursively: true) {
            let currentAngle = capNode.eulerAngles.y
            let targetAngle = degreesToRadians(capRotationY)
            let shortestPath = shortestAngleDifference(from: Float(currentAngle), to: targetAngle)
            
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 1
            capNode.eulerAngles.y = currentAngle + shortestPath
            SCNTransaction.commit()
        }
        
        if let scene = uiView.scene {
            context.coordinator.updateCapsules(numberOfCapsules: numberOfCapsules, scene: scene)
            context.coordinator.updateVisibility()
            context.coordinator.updateCapRotation() // Update the cap rotation
        }
    }

    func degreesToRadians(_ degrees: Float) -> Float {
        return degrees * .pi / 180
    }

    func shortestAngleDifference(from start: Float, to end: Float) -> Float {
        let twoPi: Float = 2 * .pi
        var diff = end - start
        
        while diff > .pi {
            diff -= twoPi
        }
        while diff < -.pi {
            diff += twoPi
        }
        
        return diff
    }
}

struct IdentViewPreviewWrapper: View {
    @State private var numberOfCapsulesDouble: Double = 40 // Use Double for slider compatibility
    @State private var showTorusAndCapsules: Bool = true
    @State private var capRotationY: Float = 69  // State variable for y-rotation of cap
    
    var body: some View {
        VStack {
            // Use Int binding for identviewa if it expects an integer
            identviewa(numberOfCapsulesInt: .constant(Int(numberOfCapsulesDouble)),
                       showTorusAndCapsules: $showTorusAndCapsules,
                       capRotationY: $capRotationY)
            
            Text("Number of Capsules: \(Int(numberOfCapsulesDouble))")
                .padding()
            
            // Slider for controlling the number of capsules
            Slider(value: $numberOfCapsulesDouble, in: 2...40, step: 1)
                .padding()
            
            Button(action: {
                withAnimation {
                    showTorusAndCapsules.toggle()
                }
            }) {
                Text(showTorusAndCapsules ? "Hide Torus and Capsules" : "Show Torus and Capsules")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
            
            // Slider for controlling the Y-rotation of the cap
            Slider(value: $capRotationY, in: 0...360, step: 1)
                .padding()
            
            Text("Cap Y-Rotation: \(Int(capRotationY))°")
                .padding()
        }
        .padding()
    }
}

struct identview: PreviewProvider {
    static var previews: some View {
        IdentViewPreviewWrapper()
    }
}
