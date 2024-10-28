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
            SCNTransaction.animationDuration = 0.5 // Adjust animation duration as needed
            let targetOpacity: CGFloat = parent.showTorusAndCapsules ? 1.0 : 0.0
            torusNode?.opacity = targetOpacity
            for node in capsuleNodes {
                node.opacity = targetOpacity
            }
            SCNTransaction.commit()
        }

        func updateCapsules(numberOfCapsules: Int, scene: SCNScene) {
            DispatchQueue.global(qos: .userInitiated).async {
                // Calculate new positions and angles
                let radius: Float = 1.5
                let angleIncrement = self.degreesToRadians(360.0 / Float(numberOfCapsules))

                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5 // Adjust animation duration as needed

                // Remove excess capsules
                while self.capsuleNodes.count > numberOfCapsules {
                    let node = self.capsuleNodes.removeLast()
                    node.removeFromParentNode()
                }

                // Add new capsules or update existing ones
                for i in 0..<numberOfCapsules {
                    let angle = angleIncrement * Float(i)
                    let x = radius * cos(angle)
                    let z = radius * sin(angle)

                    if i < self.capsuleNodes.count {
                        // Update existing capsule
                        let capsulposition = self.capsuleNodes[i]
                        capsulposition.position = SCNVector3(x: x, y: 0.5, z: z)
                    } else {
                        // Add new capsule
                        let capsuleNode = SCNNode()
                        let capsulposition = SCNNode()
                        let nodeLookAt = SCNNode()
                        let material = SCNMaterial()
                        
                        material.emission.contents = UIColor.white

                        capsuleNode.geometry = SCNCapsule(capRadius: 0.01, height: 0.2)
                        capsuleNode.eulerAngles = SCNVector3(x: self.degreesToRadians(90), y: 0, z: 0)

                        capsuleNode.geometry?.materials = [material]
                        
                        capsulposition.addChildNode(capsuleNode)

                        capsulposition.position = SCNVector3(x: x, y: 0.5, z: z)
                        capsulposition.eulerAngles = SCNVector3(x: 0, y: 0, z: self.degreesToRadians(90))
//                        nodeLookAt.geometry = SCNSphere(radius: 1)
                        nodeLookAt.position = SCNVector3(x: 0, y: 0.5, z: 0)
                        scene.rootNode.addChildNode(nodeLookAt)
                        // Point the capsule towards the origin
                        let lookAtOrigin = SCNLookAtConstraint(target: nodeLookAt)
                        capsulposition.constraints = [lookAtOrigin]

                        scene.rootNode.addChildNode(capsulposition)
                        self.capsuleNodes.append(capsulposition)
                    }
                }

                DispatchQueue.main.async {
                    self.updateVisibility()
                }

                SCNTransaction.commit()
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
                 if let tapRecognizer = recognizer as? UITapGestureRecognizer,
                    tapRecognizer.numberOfTapsRequired == 2 {
                     tapRecognizer.isEnabled = false
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

struct identview: PreviewProvider {
   
    
    static var previews: some View {
        @State var numberOfCapsulesDouble: Int = 40
        @State var showTorusAndCapsules: Bool = true
        @State var capRotationY: Float = 69  // State variable for y-rotation of cap
        
        VStack{
            identviewa(numberOfCapsulesInt: $numberOfCapsulesDouble, showTorusAndCapsules: $showTorusAndCapsules, capRotationY: $capRotationY)
            
//            Slider(value: $numberOfCapsulesDouble, in: 2...40, step: 1)
//                .padding()
            Text("Number of Capsules: \(Int(numberOfCapsulesDouble))")
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
            Slider(value: $capRotationY, in: 0...360, step: 1)
                .padding()
            Text("Cap Y-Rotation: \(Int(capRotationY))°")
                .padding()
            
        }
        
    }
}
