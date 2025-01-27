import SwiftUI

struct BluetoothView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @State private var showSettings = false
    @State private var showConnectionFailedAlert = false
    @State private var showBluetoothUnavailableAlert = false

    var body: some View {
        NavigationStack {
            Group {
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
                        .transition(.opacity) // Add transition for connected devices
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
                        .transition(.move(edge: .bottom)) // Add transition for discovered devices
                    }
                    
                    // Spinner and Text as the last item in the list
                    Section {
                        VStack {
                            if bluetoothManager.isBluetoothUnavailable {
                                // Show a cross and text when Bluetooth is unavailable
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.red)
                                    .padding()
                                Text("Enable Bluetooth to start scanning")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            } else {
                                // Show spinner and original text when Bluetooth is available
                                ProgressView() // Spinner
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .padding()
                                Text("Press Revolute once to power on. If revolute is already on, press three times to enter pairing mode")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .listRowBackground(Color.clear) // Make the background transparent
                    }
                }
                .refreshable {
                    // Trigger scanForConnectedDevices when the user pulls to refresh
                    bluetoothManager.scanForConnectedDevices()
                }
                .animation(.easeInOut, value: bluetoothManager.connectedDevices) // Animate connected devices
                .animation(.easeInOut, value: bluetoothManager.discoveredDevices) // Animate discovered devices
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
            .onChange(of: bluetoothManager.connectionFailed) { newValue in
                if newValue {
                    showConnectionFailedAlert = true
                }
            }
            .onChange(of: bluetoothManager.isBluetoothUnavailable) { newValue in
                if newValue {
                    showBluetoothUnavailableAlert = true
                }
            }
            .alert("Connection Failed", isPresented: $showConnectionFailedAlert) {
                Button("OK", role: .cancel) {
                    // Reset the connectionFailed state
                    bluetoothManager.connectionFailed = false
                }
            } message: {
                Text("Try entering pairing mode by triple pressing Revolute.")
            }
           
        }
    }
}
