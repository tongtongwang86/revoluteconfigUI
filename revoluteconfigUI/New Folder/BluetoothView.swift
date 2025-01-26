//
//  BluetoothView.swift
//  revoluteconfigUI
//
//  Created by Tong tong Wang on 1/26/25.
//
import SwiftUI

struct BluetoothView: View {
    @ObservedObject var bluetoothManager: BluetoothManager

    var body: some View {
        VStack {
            Text("Connected Bluetooth Devices")
                .font(.title)
                .padding()
            
            List {
                ForEach(bluetoothManager.connectedDevices, id: \.identifier) { peripheral in
                    VStack(alignment: .leading) {
                        Text(peripheral.name ?? "Unknown Device")
                            .font(.headline)
                        Text(peripheral.identifier.uuidString)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
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
                    }
                    .padding(.vertical, 8)
                }
                
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
        .navigationTitle("Bluetooth Devices")
    }
}
