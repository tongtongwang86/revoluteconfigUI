//
//  BluetoothView.swift
//  revoluteconfigUI
//
//  Created by Tong tong Wang on 1/26/25.
//
import SwiftUI
struct BluetoothView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Group {
                // Show spinner and message if no devices are found
                if bluetoothManager.connectedDevices.isEmpty && bluetoothManager.discoveredDevices.isEmpty {
                    VStack {
                        ProgressView() // Spinner
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                        Text("Make sure that Revolute is powered on")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
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
                                        showSettings = true
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
                    .refreshable {
                        // Trigger scanForConnectedDevices when the user pulls to refresh
                        bluetoothManager.scanForConnectedDevices()
                    }
                }
            }
            .navigationTitle("Connect Revolute")
            .navigationDestination(isPresented: $showSettings) {
                SettingsView(bluetoothManager: bluetoothManager)
            }
            .onAppear {
                bluetoothManager.startScanLoop() // Start the scan loop when the view appears
            }
            .onDisappear {
                bluetoothManager.stopScanLoop() // Stop the scan loop when the view disappears
            }
        }
    }
}

