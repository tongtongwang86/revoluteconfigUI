
//  ContentView.swift
//  revoluteconfigUI
//
//  Created by Tong tong wang on 23/07/2024.
//

import SwiftUI
struct ContentView: View {
    @State var presentSheet = false
    
    var body: some View {
        NavigationView {
            Button("Modal") {
                presentSheet = true
            }
            .navigationTitle("Main")
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
                          Text("Button 1")
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
                          Text("Button 2")
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
                  Spacer()
              }
              .frame(maxHeight: .infinity, alignment: .top) // Make VStack stick to the top
              .padding()
        
    }
}

#Preview {
    ContentView()
}
