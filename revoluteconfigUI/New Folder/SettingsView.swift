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
import UniformTypeIdentifiers
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
            
            // Select Firmware Button
            Button(action: { isDocumentPickerPresented = true }) {
                Text("Select Firmware File")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            // Display Selected Firmware File
            if let selectedFirmwareURL = selectedFirmwareURL {
                VStack(alignment: .leading) {
                    Text("Selected Firmware:")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(selectedFirmwareURL.lastPathComponent)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding()
            }
            
            // Upload Firmware Button
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
            
            // Firmware Upgrade Status
            if !bluetoothManager.firmwareUpgradeState.isEmpty {
                Text("Status: \(bluetoothManager.firmwareUpgradeState)")
                    .font(.subheadline)
                    .padding()
            }
            
            // Firmware Upload Progress
            if bluetoothManager.firmwareUpgradeProgress > 0 {
                ProgressView(value: bluetoothManager.firmwareUpgradeProgress, total: 100)
                    .padding()
                Text("\(Int(bluetoothManager.firmwareUpgradeProgress))%")
                    .font(.subheadline)
            }
            
            // Firmware Upload Speed
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
        // Define the UTType for .bin files
        let binType = UTType(filenameExtension: "bin")!
        
        // Create the document picker with the .bin file type
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [binType], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false // Allow only one file to be selected
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
            if let url = urls.first, url.pathExtension.lowercased() == "bin" {
                parent.selectedURL = url
            }
        }
    }
}
