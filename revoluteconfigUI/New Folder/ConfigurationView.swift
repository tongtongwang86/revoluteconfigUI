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
        Form {
            Section(header: Text("Deadzone")) {
                TextField("Deadzone", value: $config.deadzone, formatter: NumberFormatter())
            }
            
            Section(header: Text("Up Report")) {
                ForEach(0..<8, id: \.self) { index in
                    TextField("Byte \(index + 1)", value: $config.up_report[index], formatter: NumberFormatter())
                }
            }
            
            Section(header: Text("Up Ident Per Rev")) {
                TextField("Up Ident Per Rev", value: $config.up_identPerRev, formatter: NumberFormatter())
            }
            
            Section(header: Text("Up Transport")) {
                TextField("Up Transport", value: $config.up_transport, formatter: NumberFormatter())
            }
            
            Section(header: Text("Down Report")) {
                ForEach(0..<8, id: \.self) { index in
                    TextField("Byte \(index + 1)", value: $config.dn_report[index], formatter: NumberFormatter())
                }
            }
            
            Section(header: Text("Down Ident Per Rev")) {
                TextField("Down Ident Per Rev", value: $config.dn_identPerRev, formatter: NumberFormatter())
            }
            
            Section(header: Text("Down Transport")) {
                TextField("Down Transport", value: $config.dn_transport, formatter: NumberFormatter())
            }
            
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
        }
        .navigationTitle("Device Configuration")
    }
}
