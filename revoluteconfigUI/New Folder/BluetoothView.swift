//
//  BluetoothView.swift
//  revoluteconfigUI
//
//  Created by Tong tong Wang on 1/26/25.
//
import SwiftUI
struct BluetoothView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @State private var showSettings = false // State to control navigation to SettingsView

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    // Connected Devices
                    ForEach(bluetoothManager.connectedDevices, id: \.identifier) { peripheral in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(peripheral.name ?? "Unknown Device")
                                    .font(.headline)
                                Text(peripheral.identifier.uuidString)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            // Open/Select Button
                            Button(action: {
                                bluetoothManager.selectPeripheral(peripheral)
                            }) {
                                Text(bluetoothManager.selectedPeripheral == peripheral ? "Selected" : "Open")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(bluetoothManager.selectedPeripheral == peripheral ? Color.green : Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .disabled(bluetoothManager.selectedPeripheral == peripheral)
                            
                            // Settings Icon (Visible only for the selected device)
                            if bluetoothManager.selectedPeripheral == peripheral {
                                Button(action: {
                                    showSettings = true // Navigate to SettingsView
                                }) {
                                    Image(systemName: "gear")
                                        .foregroundColor(.blue)
                                        .padding(.leading, 8)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Discovered Devices
                    ForEach(bluetoothManager.discoveredDevices, id: \.identifier) { peripheral in
                        VStack(alignment: .leading) {
                            Text(peripheral.name ?? "Unknown Device")
                                .font(.headline)
                            Text(peripheral.identifier.uuidString)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            Button(action: {
                                bluetoothManager.connectToPeripheral(peripheral)
                            }) {
                                Text("Connect")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Scan Button
                Button(action: {
                    bluetoothManager.scanForConnectedDevices()
                }) {
                    Text("Scan for Devices")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Connect Revolute") // Updated navigation title
            .navigationDestination(isPresented: $showSettings) {
                SettingsView(bluetoothManager: bluetoothManager)
            }
        }
    }
}
