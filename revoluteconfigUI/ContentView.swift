
//  ContentView.swift
//  revoluteconfigUI
//
//  Created by Tong tong wang on 23/07/2024.
//

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
struct ContentView: View {
    @State var presentSheet = false
    
    var body: some View {
        NavigationView {
            Button("Modal") {
                presentSheet = true
            }
            .navigationTitle("Config")
        }.sheet(isPresented: $presentSheet) {
            SheetView()
            
                .presentationDetents([.fraction(0.75), .large])
        .presentationCornerRadius(50)
        .interactiveDismissDisabled(true)

        }
    }
}


struct SheetView: View {
    @State private var selectedButton: Int? = 1
    var body: some View {
        
        VStack {
                  HStack(spacing: 10) {
                      Button(action: {
                          selectedButton = 1
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

                      Button(action: {
                          selectedButton = 2
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
                  }
                  .frame(maxWidth: .infinity) // Make HStack take full width
                  .padding([.top, .leading, .trailing])
                  .padding(.bottom, 5)
//                    .border(.red)
            
            if selectedButton == 1 {
                
                DropDownMenu()
                
            }else {
                
                SensitivityView()
                
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
            
      
            
            
            
            RatingView(rating: $IdentPerRevolution, maxVal: 40, minVal: 2, distPerIdent: 15)

            
            Text("Dead Zone (Degrees)")
                
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10.0)
                .padding([.leading, .trailing])
                .padding(.bottom, -20.0)
                .dynamicTypeSize(.xxLarge)
//                .border(.red)
            RatingView(rating: $deadZone, maxVal: 10, minVal: 0, distPerIdent: 20)
            
            
            
            
            
            
            
            
            
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
                                    print(dragOffset)
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
            }
        }
        .padding()
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


struct DropDownMenu: View {
    var fruits = ["Mouse", "Consumer", "Keyboard"]
    @State private var selectedFruit: String = "Mouse"
    
    var body: some View {
        VStack {
            Menu(
                content: {
                    Picker("fruits", selection: $selectedFruit) {
                        ForEach(fruits, id: \.self) { fruit in
                            Text(fruit)
                        }
                    }
                }, label: {
                    (Text("\(selectedFruit) ") + Text(Image(systemName: "chevron.down")))

                        .padding()
                        .foregroundColor(.white)
                        .cornerRadius(16)
                                        
                        .frame(maxWidth: .infinity) // Make the button span the width of the screen
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(16)
                })
//            .border(.red)
                .contentShape(Rectangle()) // Make the hitbox area larger
        }
//        .border(.red)
        .padding([.leading, .bottom, .trailing]) // Add padding to the VStack to avoid edge clipping
    }
}







#Preview {
    ContentView()
}
