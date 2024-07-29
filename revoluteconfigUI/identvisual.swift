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
    @State private var numberOfCapsulesDouble: Double = 8
    @State private var showTorusAndCapsules: Bool = true

    var body: some View {
        VStack {
            SceneKitView(numberOfCapsules: Int(numberOfCapsulesDouble), showTorusAndCapsules: $showTorusAndCapsules)
                .frame(width: 600, height: 600)
                .background(Color.gray)
            Slider(value: $numberOfCapsulesDouble, in: 2...40, step: 1)
                .padding()
            Text("Number of Capsules: \(Int(numberOfCapsulesDouble))")
                .padding()
            Button(action: {
                showTorusAndCapsules.toggle()
            }) {
                Text(showTorusAndCapsules ? "Hide Torus and Capsules" : "Show Torus and Capsules")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
}

struct SceneKitView: UIViewRepresentable {
    var numberOfCapsules: Int
    @Binding var showTorusAndCapsules: Bool

    class Coordinator: NSObject {
        var parent: SceneKitView
        var capsuleNodes: [SCNNode] = []
        var torusNode: SCNNode?

        init(parent: SceneKitView) {
            self.parent = parent
        }

        func updateVisibility() {
            torusNode?.isHidden = !parent.showTorusAndCapsules
            for node in capsuleNodes {
                node.isHidden = !parent.showTorusAndCapsules
            }
        }

        func updateCapsules(numberOfCapsules: Int, scene: SCNScene) {
            DispatchQueue.global(qos: .userInitiated).async {
                // Calculate new positions and angles
                let radius: Float = 1.0
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
                        capsulposition.position = SCNVector3(x: x, y: 0, z: z)
                    } else {
                        // Add new capsule
                        let capsuleNode = SCNNode()
                        let capsulposition = SCNNode()
                        let material = SCNMaterial()

                        material.emission.contents = UIColor.white

                        capsulposition.geometry = SCNBox()
                        capsuleNode.geometry = SCNCapsule(capRadius: 0.02, height: 0.1)
                        capsuleNode.eulerAngles = SCNVector3(x: self.degreesToRadians(90), y: 0, z: 0)

                        capsulposition.geometry?.materials = [material]
                        capsulposition.addChildNode(capsuleNode)

                        capsulposition.position = SCNVector3(x: x, y: 0, z: z)
                        capsulposition.eulerAngles = SCNVector3(x: 0, y: 0, z: self.degreesToRadians(90))

                        // Point the capsule towards the origin
                        let lookAtOrigin = SCNLookAtConstraint(target: scene.rootNode)
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
        sceneView.debugOptions = [.renderAsWireframe, SCNDebugOptions(rawValue: 2048)]

        // Create the scene
        let scene = SCNScene()

        // Create a camera node
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.fieldOfView = 20
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        scene.rootNode.addChildNode(cameraNode)

        // Create the torus node
        let torus = SCNNode()
        torus.geometry = SCNTorus(ringRadius: 1, pipeRadius: 0.2)
        scene.rootNode.addChildNode(torus)
        context.coordinator.torusNode = torus

        sceneView.scene = scene
        context.coordinator.updateCapsules(numberOfCapsules: numberOfCapsules, scene: scene)
        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        if let scene = uiView.scene {
            context.coordinator.updateCapsules(numberOfCapsules: numberOfCapsules, scene: scene)
            context.coordinator.updateVisibility()
        }
    }
}


struct identview: PreviewProvider {
    static var previews: some View {
        identviewa()
    }
}
