//
//  Scene.swift
//  revoluteconfigUI
//
//  Created by Tong tong wang on 25/07/2024.
//

import Foundation
import SwiftUI
import SceneKit

extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}


struct SceneViewContainer: UIViewRepresentable {
    @Binding var capRotationY: Float
    @Binding var showRing: Bool
    var ringNode = SCNNode()

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = makeScene()
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true
        
        updateBackgroundColor(sceneView: sceneView)
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        updateSceneView(uiView)
    }
}

extension SceneViewContainer {
    func makeScene() -> SCNScene {
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
        
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        
        func highResCircularPath(center: CGPoint, radius: CGFloat, segments: Int) -> UIBezierPath {
            let path = UIBezierPath()
            let angleIncrement = (CGFloat.pi * 2) / CGFloat(segments)
            
            for i in 0..<segments {
                let angle = angleIncrement * CGFloat(i)
                let point = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
                
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.close()
            return path
        }

        // Define outer and inner circles with increased resolution
        let outerRadius: CGFloat = 1.9
        let innerRadius: CGFloat = 1.8
        let center = CGPoint(x: 0, y: 0)
        let segments = 30 // Increase this value for higher resolution

        let outerCirclePath = highResCircularPath(center: center, radius: outerRadius, segments: segments)
        let innerCirclePath = highResCircularPath(center: center, radius: innerRadius, segments: segments)

        // Combine paths to create a ring
        outerCirclePath.append(innerCirclePath.reversing())

        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        material.emission.contents = UIColor.white
        material.isDoubleSided = true

        let ringShape = SCNShape(path: outerCirclePath, extrusionDepth: 0.05)
        ringShape.materials = [material]

        ringNode.geometry = ringShape

        // Rotate the ring 90 degrees along the Z-axis
        ringNode.eulerAngles.x = .pi / 2
        ringNode.position = SCNVector3(0, 0.3,0 )
        
        // Add ringNode to the scene
        scene.rootNode.addChildNode(ringNode)
        
        camera.fieldOfView = 20
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 4, y: 5, z: 10)
        #if os(macOS)
        cameraNode.eulerAngles = SCNVector3(x: CGFloat(degreesToRadians(27)), y: 0, z: 0)
        #else
        cameraNode.eulerAngles = SCNVector3(x: degreesToRadians(27), y: 0, z: 0)
        #endif
        scene.rootNode.addChildNode(cameraNode)
        
        if let capNode = scene.rootNode.childNode(withName: "cap", recursively: true) {
            let lookAtConstraint = SCNLookAtConstraint(target: capNode)
            cameraNode.constraints = [lookAtConstraint]
        }
        
        return scene
    }
    
    func updateSceneView(_ sceneView: SCNView) {
        if let capNode = sceneView.scene?.rootNode.childNode(withName: "cap", recursively: true) {
            let currentAngle = capNode.eulerAngles.y
            let targetAngle = degreesToRadians(capRotationY)
            let shortestPath = shortestAngleDifference(from: Float(currentAngle), to: targetAngle)
            
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 1
            
            capNode.eulerAngles.y = currentAngle + shortestPath
            
            // Animate the visibility change of the ringNode
            print(showRing)
            
            if (showRing){
                
                ringNode.opacity = 100
                
            }else {
                
                ringNode.opacity = 0
            }
             
            SCNTransaction.commit()
        }
        updateBackgroundColor(sceneView: sceneView)
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
    
    func updateBackgroundColor(sceneView: SCNView) {
        sceneView.backgroundColor = .clear
    }
}
