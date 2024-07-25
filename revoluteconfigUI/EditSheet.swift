//
//  EditSheet.swift
//  revoluteconfigUI
//
//  Created by Tong tong wang on 25/07/2024.
//
import SwiftUI
import Foundation
import Combine

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


struct EditSheet_Previews: PreviewProvider {
    static var previews: some View {
        
        SheetView()
    }
}
