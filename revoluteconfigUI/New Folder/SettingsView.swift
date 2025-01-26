//
//  SettingsView 2.swift
//  revoluteconfigUI
//
//  Created by Tong tong Wang on 1/26/25.
//


//
//  SettingsView.swift
//  revoluteconfigUI
//
//  Created by Tong tong Wang on 1/26/25.
//

import SwiftUI
import CoreBluetooth
import Combine
import iOSMcuManagerLibrary

struct SettingsView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @State private var selectedFirmwareURL: URL?
    @State private var isDocumentPickerPresented = false

    var body: some View {
        VStack {
            Text("Firmware Upgrade")
                .font(.title)
                .padding()
            
            Button(action: { isDocumentPickerPresented = true }) {
                Text("Select Firmware File")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            Button(action: {
                bluetoothManager.startFirmwareUpgrade(with: selectedFirmwareURL)
            }) {
                Text("Upload Firmware")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(selectedFirmwareURL == nil || bluetoothManager.selectedPeripheral == nil)
            .padding()
            
            if !bluetoothManager.firmwareUpgradeState.isEmpty {
                Text("Status: \(bluetoothManager.firmwareUpgradeState)")
                    .font(.subheadline)
                    .padding()
            }
            
            if bluetoothManager.firmwareUpgradeProgress > 0 {
                ProgressView(value: bluetoothManager.firmwareUpgradeProgress, total: 100)
                    .padding()
                Text("\(Int(bluetoothManager.firmwareUpgradeProgress))%")
                    .font(.subheadline)
            }
            
            if !bluetoothManager.firmwareUploadSpeed.isEmpty {
                Text("Speed: \(bluetoothManager.firmwareUploadSpeed)")
                    .font(.subheadline)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Settings")
        .sheet(isPresented: $isDocumentPickerPresented) {
            DocumentPicker(selectedURL: $selectedFirmwareURL)
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.selectedURL = urls.first
        }
    }
}
