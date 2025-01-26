//
//  ConfigurationView.swift
//  revoluteconfigUI
//
//  Created by Tong tong Wang on 1/26/25.
//

import SwiftUI

struct ConfigurationView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @State private var config = Config()

    var body: some View {
        NavigationStack {
            Form {
                // Deadzone
                Section(header: Text("Deadzone")) {
                    TextField("Deadzone", value: $config.deadzone, formatter: NumberFormatter())
                        .textFieldStyle(.plain) // Remove background
                }
                
                // Up Report
                Section(header: Text("Up Report")) {
                    ForEach(0..<8, id: \.self) { index in
                        TextField("Byte \(index + 1)", value: $config.up_report[index], formatter: NumberFormatter())
                            .textFieldStyle(.plain) // Remove background
                    }
                }
                
                // Up Ident Per Rev
                Section(header: Text("Up Ident Per Rev")) {
                    TextField("Up Ident Per Rev", value: $config.up_identPerRev, formatter: NumberFormatter())
                        .textFieldStyle(.plain) // Remove background
                }
                
                // Up Transport
                Section(header: Text("Up Transport")) {
                    TextField("Up Transport", value: $config.up_transport, formatter: NumberFormatter())
                        .textFieldStyle(.plain) // Remove background
                }
                
                // Down Report
                Section(header: Text("Down Report")) {
                    ForEach(0..<8, id: \.self) { index in
                        TextField("Byte \(index + 1)", value: $config.dn_report[index], formatter: NumberFormatter())
                            .textFieldStyle(.plain) // Remove background
                    }
                }
                
                // Down Ident Per Rev
                Section(header: Text("Down Ident Per Rev")) {
                    TextField("Down Ident Per Rev", value: $config.dn_identPerRev, formatter: NumberFormatter())
                        .textFieldStyle(.plain) // Remove background
                }
                
                // Down Transport
                Section(header: Text("Down Transport")) {
                    TextField("Down Transport", value: $config.dn_transport, formatter: NumberFormatter())
                        .textFieldStyle(.plain) // Remove background
                }
                
                // Send Configuration Button
                Button(action: {
                    bluetoothManager.sendConfig(config)
                }) {
                    Text("Send Configuration")
                        .frame(maxWidth: .infinity)
                }
                .disabled(bluetoothManager.selectedPeripheral == nil)
                .padding()
                .background(bluetoothManager.selectedPeripheral != nil ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding()
            .navigationTitle("Device Configuration")
        }
    }
}
