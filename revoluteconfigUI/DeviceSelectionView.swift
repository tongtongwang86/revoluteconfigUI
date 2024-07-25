//
//  DeviceSelectionView.swift
//  revoluteconfigUI
//
//  Created by Tong tong wang on 25/07/2024.
//
import SwiftUI
import Foundation
import Combine

struct DeviceSelectionView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @Binding var isDeviceConnected: Bool
//    @State var presentSheet = false
    var body: some View {
        VStack {
            Text("Waiting for revolute...")
                .font(.title)
                .padding(.top, 20)
            
            List(bluetoothManager.availableDevices, id: \.identifier) { peripheral in
                HStack{
                    Text(peripheral.name ?? "Unknown Device")
                    
//                    Button(action: {
//                        bluetoothManager.connect(to: peripheral)
//                    }) {Label:
//                        
//                        
//                    }
                    
                    Button {
                        
                        bluetoothManager.connect(to: peripheral)
                        HapticFeedbackManager.shared.playImpactFeedback()
                    }label: {
                        Text("Connect")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding([.top, .leading, .trailing,.bottom],(20))
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(16)
                    
                    
                }
                
            }
            
            Button(action: {
                bluetoothManager.startScanning()
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
        }
    }
}


struct DeviceSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        @State var isDeviceConnected = true
        DeviceSelectionView(bluetoothManager: BluetoothManager(), isDeviceConnected: $isDeviceConnected)
    }
}
