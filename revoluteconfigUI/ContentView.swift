
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
                  .padding()
            
            SensitivityView()
               
              }
              .frame(maxHeight: .infinity, alignment: .top) // Make VStack stick to the top
              .padding()
        
        
        
    }
}


struct SensitivityView: View {
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
            
      
            
            
            RatingView()
            
            Text("Dead Zone (Degrees)")
                
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10.0)
                .padding([.leading, .trailing])
                .padding(.bottom, -20.0)
                .dynamicTypeSize(.xxLarge)
//                .border(.red)
            RatingView()
            
            
            
            
            
            
            
            
        }.frame(maxHeight: .infinity, alignment: .top)
        
        
        
    }
    
}


struct RatingView: View {
    @State private var rating: Int = 30
    @State private var dragOffset: CGFloat = 0
    
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
                .disabled(rating == 2)
                
                GeometryReader { geometry in
                    Text("\(rating)")
                        .font(.system(size: 75))
                        .bold()
                        .contentTransition(.numericText(value: Double(rating)))
                        .frame(width: geometry.size.width)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let width = geometry.size.width
                                    dragOffset = value.translation.width
                                    withAnimation {
                                        let newRating = Int((dragOffset / width) * 16) + 20
                                        if newRating != rating {
                                            rating = min(max(newRating, 2), 40)
                                            HapticFeedbackManager.shared.playImpactFeedback() // Play haptic feedback
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    dragOffset = 0
                                }
                        )
                }
                .frame(width: 150, height: 90) // Fixed width for the GeometryReader
                
                Button(action: {
                    withAnimation {
                        rating += 1
                        HapticFeedbackManager.shared.playImpactFeedback() // Play haptic feedback
                    }
                }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 50))
                }
                .disabled(rating == 40)
            }
        }
        .padding()
    }
}






#Preview {
    ContentView()
}
