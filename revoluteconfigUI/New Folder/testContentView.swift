//
//  ContentView 2.swift
//  revoluteconfigUI
//
//  Created by Tong tong Wang on 1/26/25.
//

import SwiftUI
import CoreBluetooth
import Combine
import iOSMcuManagerLibrary


struct testContentView: View {
    @StateObject var bluetoothManager = BluetoothManager()

    var body: some View {
        TabView {
            // Bluetooth View (Default Tab)
            BluetoothView(bluetoothManager: bluetoothManager)
                .tabItem {
                    Label("Devices", systemImage: "antenna.radiowaves.left.and.right")
                }
            
            // Configuration View
            ConfigurationView(bluetoothManager: bluetoothManager)
                .tabItem {
                    Label("Configuration", systemImage: "gear")
                }
            
            // Settings View
            SettingsView(bluetoothManager: bluetoothManager)
                .tabItem {
                    Label("Settings", systemImage: "slider.horizontal.3")
                }
        }
    }
}
