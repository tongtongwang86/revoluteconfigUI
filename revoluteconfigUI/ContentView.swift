
//  ContentView.swift
//  revoluteconfigUI
//
//  Created by Tong tong wang on 23/07/2024.
//

extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}

import SceneKit

struct SceneViewContainer: UIViewRepresentable {
    @Binding var capRotationY: Float
    @Environment(\.colorScheme) var colorScheme
    
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
        let segments = 100 // Increase this value for higher resolution

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

        let ringNode = SCNNode()
        ringNode.geometry = ringShape

        // Rotate the ring 90 degrees along the Z-axis
        ringNode.eulerAngles.x = .pi / 2
        ringNode.position = SCNVector3(0, 0.3,0 )
        

        // Assuming `scene` is your SCNScene
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

import UIKit

class HapticFeedbackManager {
    static let shared = HapticFeedbackManager()

    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    private init() {}

    func playImpactFeedback() {
        impactFeedbackGenerator.impactOccurred()
    }
}

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @ObservedObject var bluetoothManager = BluetoothManager()
    @Environment(\.colorScheme) var colorScheme
    @State var presentSheet = false
    @State private var isDeviceConnected = false
    @State private var selectedPeripheral: CBPeripheral?
    
    var body: some View {
        NavigationView {
            VStack {
                SquareBoxView(bluetoothManager: bluetoothManager)
                Spacer()
                
                
                
                Text("Waiting for revolute...")
                                .font(.title)
                                .padding(.top, 20)

                            List(bluetoothManager.availableDevices + bluetoothManager.connectedDevices, id: \.identifier) { peripheral in
                                HStack {
                                    
                                    Text(peripheral.name ?? "Unknown Device")

                                    Button(action: {
                                        selectedPeripheral = peripheral
                                        presentSheet = true
                                        if !bluetoothManager.connectedDevices.contains(peripheral) {
                                            bluetoothManager.connect(to: peripheral)
                                        }
                                        HapticFeedbackManager.shared.playImpactFeedback()
                                    }) {
                                        Text(bluetoothManager.connectedDevices.contains(peripheral) ? "Open" : "Connect")
                                            .padding()
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.3))
                                            .cornerRadius(16)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                            }

                            Button(action: {
//                                bluetoothManager.startScanning()
                                bluetoothManager.scanAndRetrievePairedDevices()

                            }) {
                                Text("Scan for devices")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .padding(.top, 20)
                        }
                        .onAppear {
                            bluetoothManager.startScanning()
                        }
                        .onChange(of: bluetoothManager.isConnected) { newValue in
                            isDeviceConnected = newValue
                            if isDeviceConnected == false {
                                
                                presentSheet = false
                                
                            }
                        }
                        .sheet(isPresented: $presentSheet) {
                            // Your sheet content here
                            VStack {
                                Text("Device Details")
                                // Add more details or controls as needed
                            }
                        }
            
            
            
            
            
            
            
            .background(
                VStack {
                    Spacer()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        if colorScheme == .dark {
                            Text("Configurator")
                            
                                .font(.largeTitle)
                                .bold()
                                .padding(.top, 50)
                                .shadow(color: .black, radius: 25, x: 0, y: 0)
                                .shadow(color: .black, radius: 25, x: 0, y: 0)
                                .shadow(color: .black, radius: 20, x: 0, y: 0)

                            
                        }else{
                            Text("Configurator")
                            
                                .font(.largeTitle)
                                .bold()
                                .padding(.top, 50)
                                .shadow(color: .white, radius: 15, x: 0, y: 0)
                                .shadow(color: .white, radius: 15, x: 0, y: 0)
                                .shadow(color: .white, radius: 15, x: 0, y: 0)
                                .shadow(color: .white, radius: 15, x: 0, y: 0)
                        }
                    }
                }
            )
        }
        .sheet(isPresented: $presentSheet) {
            SheetView()
                .presentationDetents([.fraction(0.75), .large])
                .presentationCornerRadius(50)
                .interactiveDismissDisabled(true)
        }
        .navigationViewStyle(StackNavigationViewStyle()) // This line can help ensure that the nav view style is correct on all devices
        .hiddenNavigationBar() // Custom modifier to hide the navigation bar
    }
}

extension View {
    func hiddenNavigationBar() -> some View {
        self.modifier(HideNavigationBarModifier())
    }
}

struct HideNavigationBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(NavigationConfigurator { nc in
                nc.navigationBar.isHidden = true
            })
    }
}

struct NavigationConfigurator: UIViewControllerRepresentable {
    var configure: (UINavigationController) -> Void = { _ in }
    
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let nc = uiViewController.navigationController {
            self.configure(nc)
        }
    }
}

struct WindowBackgroundColorView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Color.clear
            .edgesIgnoringSafeArea(.all)
    }
}

struct SheetView: View {
    @State private var selectedButton: Int? = 1
    @StateObject private var viewModel = ReportViewModel()
    
    var body: some View {
        
        VStack {
                  HStack(spacing: 10) {
                      Button(action: {
                          HapticFeedbackManager.shared.playImpactFeedback()
                          withAnimation {
                        selectedButton = 1
                         }

                        
                      }) {
                          Text("Action")
                              .frame(maxWidth: .infinity)
                              .padding()
                              .background(Color.black.opacity(0.3))
                              .foregroundColor(.white)
                              .cornerRadius(15)
                              .overlay(
                                  RoundedRectangle(cornerRadius: 15)
                                      .stroke(selectedButton == 1 ? Color.blue : Color.clear, lineWidth: 2)
                              )
                      }
                      .onPressGesture(
                          minimumDuration: 0.0,
                          perform: {
                              HapticFeedbackManager.shared.playImpactFeedback() // Play haptic feedback on press
                          },
                          onPressingChanged: { pressing in
                              if !pressing {
                                  HapticFeedbackManager.shared.playImpactFeedback() // Play haptic feedback on release
                              }
                          }
                      )

                      Button(action: {
                          HapticFeedbackManager.shared.playImpactFeedback()
                          withAnimation {
                              selectedButton = 2
                              viewModel.isEditing = false
                              UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

                          }
                      }) {
                          Text("Sensitivity")
                              .frame(maxWidth: .infinity)
                              .padding()
                              .background(Color.black.opacity(0.3))
                              .foregroundColor(.white)
                              .cornerRadius(15)
                              
                              .overlay(
                                  RoundedRectangle(cornerRadius: 15)
                                      .stroke(selectedButton == 2 ? Color.blue : Color.clear, lineWidth: 2)
                              )
                      }
                      .onPressGesture(
                          minimumDuration: 0.0,
                          perform: {
                              HapticFeedbackManager.shared.playImpactFeedback() // Play haptic feedback on press
                          },
                          onPressingChanged: { pressing in
                              if !pressing {
                                  HapticFeedbackManager.shared.playImpactFeedback() // Play haptic feedback on release
                              }
                          }
                      )
                      
                      
                  }
                  .frame(maxWidth: .infinity) // Make HStack take full width
                  .padding([.top, .leading, .trailing])
                  .padding(.bottom, 5)
//                    .border(.red)
            
            if selectedButton == 1 {
                
//                ActionView()
                ReportListView(bluetoothManager: BluetoothManager())
                
                    .transition(.scale(scale: 0.8, anchor: UnitPoint(x: 0, y: 0)).combined(with: .move(edge: .leading)))
                
                
//                    .transition(.move(edge: .leading).combined(with: .scale(0.5))) // Add fade transition
//                    .transition(.move(edge: .leading).combined(with: .scale(0.8, anchor: UnitPoint(x: 0, y: 0)))) // Add fade transition
                    
                
            }else {
                
                SensitivityView(bluetoothManager: BluetoothManager())
                    
//                    .transition(.move(edge: .trailing)) // Add fade transition
//                    .transition(.move(edge: .trailing).combined(with: .scale(0.8, anchor: UnitPoint(x: 0, y: 0)))) // Add fade transition
//                    .transition(.move(edge: .trailing).combined(with: .scale(0.5)))
                
                    .transition(.scale(scale: 0.8, anchor: UnitPoint(x: 1, y: 0)).combined(with: .move(edge: .trailing)))
                    
                
            }
            
            
               
              }
        
              .frame(maxHeight: .infinity, alignment: .top) // Make VStack stick to the top
              .padding()
        
        
        
    }
}


struct SensitivityView: View {
    
    @State private var IdentPerRevolution: Int = 30 //set default
    @State private var deadZone: Int = 1 //set default
    @State private var rating3: Int = 50
    @ObservedObject var bluetoothManager: BluetoothManager
    
    @State private var sliderValue1: Double = 0.5
    @State private var sliderValue2: Double = 0.5
    @State private var rating: Int = 5
    
    var body: some View {
        
        
        
        VStack{
            
            
            Text("Ident Per Revolution")
                
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10.0)
                .padding([.leading, .trailing])
                .padding(.bottom, -20.0)
                .dynamicTypeSize(.xxLarge)
            
      
            
            
            
            RatingView(rating: $IdentPerRevolution, maxVal: 40, minVal: 2, distPerIdent: 15).onChange(of: IdentPerRevolution) { oldValue, newValue in
                let uint8ident = UInt8(newValue)
                var uint8identarray: [UInt8] = []
                uint8identarray.append(uint8ident)
                bluetoothManager.writeNumIdentReport(byteArray: uint8identarray)
                print("ident set as:")
                print(IdentPerRevolution)
                
            }
            
            
            
            
    
            
         

            
            Text("Dead Zone (Degrees)")
                
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10.0)
                .padding([.leading, .trailing])
                .padding(.bottom, -20.0)
                .dynamicTypeSize(.xxLarge)
//                .border(.red)
            
            
            RatingView(rating: $deadZone, maxVal: 10, minVal: 0, distPerIdent: 20).onChange(of: deadZone) { oldValue, newValue in
                let uint8dead = UInt8(newValue)
                var uint8deadarray: [UInt8] = []
                uint8deadarray.append(uint8dead)
                bluetoothManager.writeDeadZoneReport(byteArray: uint8deadarray)
                print("deadzone set as:")
                print(deadZone)
                
            }
            
            
         
            
            
            
            
            
            
            
            
            
        }
        .frame(maxHeight: .infinity, alignment: .top)
        
        
        
    }
    
}


struct RatingView: View {
    
//    @State private var rating: Int
    @Binding var rating: Int
    @State private var dragOffset: CGFloat = 0
    @State private var lastDragOffset: CGFloat = 0
    

    let maxVal: Int
    let minVal: Int
    let distPerIdent: CGFloat
    
    
    
    var body: some View {
        VStack {
            HStack {
                
                Button(action: {
                    withAnimation {
                        rating -= 1
                        HapticFeedbackManager.shared.playImpactFeedback() // Play haptic feedback
                    }
                }) {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 50))
                }
                .disabled(rating == minVal)
                .onPressGesture(
                    minimumDuration: 0.0,
                    perform: {
                        HapticFeedbackManager.shared.playImpactFeedback() // Play haptic feedback on press
                    },
                    onPressingChanged: { pressing in
                        if !pressing {
                            HapticFeedbackManager.shared.playImpactFeedback() // Play haptic feedback on release
                        }
                    }
                )
                
                
                    Text("\(rating)")
                        .font(.system(size: 75))
                        .bold()
                        .padding(.horizontal, 50)
//                        .frame(width: 200.0)
                        .contentTransition(.numericText(value: Double(rating)))
//                        .frame(width: geometry.size.width)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    
                                    dragOffset = value.translation.width
//                                    print(dragOffset)
                                    withAnimation {
                                        if (lastDragOffset - dragOffset) > distPerIdent{
                                            if rating > minVal{
                                                
                                      
                                                
                                                rating -= 1
                                                HapticFeedbackManager.shared.playImpactFeedback()
                                                lastDragOffset = dragOffset
                                            }
                                        }else if (lastDragOffset - dragOffset) < (-distPerIdent) {
                                            if rating < maxVal{
                                                
                                                
                                           
                                                
                                                
                                                rating += 1
                                                HapticFeedbackManager.shared.playImpactFeedback()
                                                lastDragOffset = dragOffset
                                            }
                                        }
                                        
                    
                                    }
                                }
                            
                                .onEnded { _ in
                                    dragOffset = 0
                                }
                        )
                
//                .frame(width: 150, height: 90) // Fixed width for the GeometryReader
                        
//                .border(.red)
                
                
                Button(action: {
                    withAnimation {
                        rating += 1
                        HapticFeedbackManager.shared.playImpactFeedback() // Play haptic feedback
                    }
                }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 50))
                }
                .disabled(rating == maxVal)
                .onPressGesture(
                    minimumDuration: 0.0,
                    perform: {
                        HapticFeedbackManager.shared.playImpactFeedback() // Play haptic feedback on press
                    },
                    onPressingChanged: { pressing in
                        if !pressing {
                            HapticFeedbackManager.shared.playImpactFeedback() // Play haptic feedback on release
                        }
                    }
                )
            }
        }
        .padding()
    }
}


extension View {
    func onPressGesture(minimumDuration: Double = 0.0, perform action: @escaping () -> Void, onPressingChanged: @escaping (Bool) -> Void) -> some View {
        self.simultaneousGesture(
            LongPressGesture(minimumDuration: minimumDuration)
                .onEnded { _ in action() }
                .onChanged { pressing in onPressingChanged(pressing) }
        )
    }
}



struct circle: View {
    // how far the circle has been dragged
    @State private var offset = CGSize.zero

    // whether it is currently being dragged or not
    @State private var isDragging = false

    var body: some View {
        // a drag gesture that updates offset and isDragging as it moves around
        let dragGesture = DragGesture()
            .onChanged { value in offset = value.translation }
            .onEnded { _ in
                withAnimation {
                    offset = .zero
                    isDragging = false
                }
            }

        // a long press gesture that enables isDragging
        let pressGesture = LongPressGesture()
            .onEnded { value in
                withAnimation {
                    isDragging = true
                }
            }

        // a combined gesture that forces the user to long press then drag
        let combined = pressGesture.sequenced(before: dragGesture)

        // a 64x64 circle that scales up when it's dragged, sets its offset to whatever we had back from the drag gesture, and uses our combined gesture
        Circle()
            .fill(.red)
            .frame(width: 64, height: 64)
            .scaleEffect(isDragging ? 1.5 : 1)
            .offset(offset)
            .gesture(combined)
    }
}



struct ActionView: View {
    var modes = [("Mouse", "computermouse"), ("Consumer", "slider.vertical.3"), ("Keyboard", "keyboard")]
    @State private var selectedMode: String = "Mouse"
    @State private var searchText: String = ""
    
    
    var body: some View {
        VStack {
            Menu {
                Picker("modes", selection: $selectedMode) {
                    ForEach(modes, id: \.0) { mode in
                        Label(mode.0, systemImage: mode.1).tag(mode.0)
                    }
                }
            } label: {
                (Text("\(selectedMode) ") + Text(Image(systemName: "chevron.down")))
                    .padding()
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .frame(maxWidth: .infinity) // Make the button span the width of the screen
                    .background(Color(.black).opacity(0.5))
                    .cornerRadius(16)
            }
            .contentShape(Rectangle())
            
            
            TextField("Search", text: $searchText)
            
            
                .foregroundColor(.white)
                .padding(.all)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.3))
                .cornerRadius(16)

//                            .background(Color(.systemGray5))
//                            .cornerRadius(8)
//                            .padding([.leading, .trailing, .top])
            
            ScrollView{
                
                if selectedMode == "Mouse" {
                    ListView(title: "Mouse List", items: ["Item 1", "Item 2", "Item 3"], searchText: searchText)
                } else if selectedMode == "Consumer" {
                    ListView(title: "Consumer List", items: ["Item A", "Item B", "Item C"], searchText: searchText)
                } else if selectedMode == "Keyboard" {
                    ListView(title: "Keyboard List", items: ["Item X", "Item Y", "Item Z"], searchText: searchText)
                }
            }.cornerRadius(16)
        }
        .padding([.leading, .bottom, .trailing])
    }
}

struct ListView: View {
    var title: String
       var items: [String]
       var searchText: String
       
    var filteredItems: [String] {
        if searchText.isEmpty {
            return items
        } else {
            let formattedSearchText = searchText.lowercased().replacingOccurrences(of: " ", with: "")
            return items.filter { item in
                item.lowercased().replacingOccurrences(of: " ", with: "").contains(formattedSearchText)
            }
        }
    }
    
    var body: some View {

            ForEach(filteredItems, id: \.self) { item in
                HStack{
                    
                    Text(item)
    //                     .padding()
                        .foregroundColor(.white)
                        .padding([.top,.bottom])
                        .frame(maxWidth: .infinity) // Make the button span the width of the screen
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(16)
                    
                    HStack{
                        
                        Button(action: {
                            // Action to perform when the button is tapped
                        }) {
                            Image(systemName: "digitalcrown.horizontal.arrow.clockwise")
                                .foregroundColor(.white)
                                .padding([.top, .bottom])
                                .frame(maxWidth: .infinity)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(16)
                        }
                        
                        Button(action: {
                            // Action to perform when the button is tapped
                        }) {
                            Image(systemName: "digitalcrown.horizontal.arrow.counterclockwise")
                                .foregroundColor(.white)
                                .padding([.top, .bottom])
                                .frame(maxWidth: .infinity)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(16)
                        }






                        
                        
                    }
                    
                    
                    
                    
                }
              
                
            }
//            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
//            .cornerRadius(16)
            
//            .border(.red)
            .frame(maxWidth: .infinity)
            
        
        
        
    }
}


struct SquareBoxView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    var body: some View {
        
        SceneViewContainer(
            
            capRotationY: .constant(Float(bluetoothManager.uint16Value)
//                .constant(Float(bluetoothManager.uint16Value))
            
                                   )
        
        
        )
//        .border(.red)
        .frame(maxWidth: UIScreen.screenWidth, maxHeight: UIScreen.screenWidth)
        .background(WindowBackgroundColorView())
        .edgesIgnoringSafeArea(.top)
            
            
        

    }
}





#Preview {
    ContentView()
}
