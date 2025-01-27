import Foundation
import CoreBluetooth
import Combine
import iOSMcuManagerLibrary

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate, FirmwareUpgradeDelegate, McuMgrLogDelegate {
    private var centralManager: CBCentralManager!
    @Published var connectedDevices: [CBPeripheral] = []
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var selectedPeripheral: CBPeripheral? = nil
    @Published var isBluetoothUnavailable = false
    @Published var connectionFailed = false

    // Define the UUIDs
    let serviceUUID = CBUUID(string: "00000000-0000-0000-0000-003323DE1223")
    let advertisedUUID = CBUUID(string: "00001523-1212-efde-1523-785feabcd133") // New UUID for scanning
    let writeUUID = CBUUID(string: "00000000-0000-0000-0000-003323DE1226") // Write characteristic

    // Firmware Upgrade Properties
    @Published var firmwareUpgradeState: String = ""
    @Published var firmwareUpgradeProgress: Double = 0
    @Published var firmwareUploadSpeed: String = ""
    private var uploadTimestamp: Date = Date()
    private var uploadImageSize: Int?
    private var initialBytes: Int = 0
    private var totalBytesUploaded: Int = 0

    // Timer for scan loop
    private var scanTimer: Timer?

    // Timer for connection timeout
    private var connectionTimer: Timer?
    private let connectionTimeout: TimeInterval = 1.0 // 10 seconds timeout

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScanLoop() {
        // Invalidate any existing timer
        stopScanLoop()

        // Start a new timer that calls scanForConnectedDevices every 1 second
        scanTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.scanForConnectedDevices()
        }
    }

    func stopScanLoop() {
        // Invalidate the timer to stop the loop
        scanTimer?.invalidate()
        scanTimer = nil
    }

    func scanForConnectedDevices() {
        // Retrieve peripherals already connected to the system that advertise the specified service UUID
        let connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: [serviceUUID])

        // Clear the previous lists
        connectedDevices.removeAll()
        discoveredDevices.removeAll()

        // Connect to each peripheral and discover services
        for peripheral in connectedPeripherals {
            // Ensure the peripheral is actually connected
            if peripheral.state == .connected {
                peripheral.delegate = self
                connectedDevices.append(peripheral)
            } else {
                // If not connected, attempt to reconnect
                centralManager.connect(peripheral, options: nil)
            }
        }

        // Start scanning for peripherals advertising the specified UUID
        centralManager.scanForPeripherals(withServices: [advertisedUUID], options: nil)
        print("Scanning for devices advertising UUID: \(advertisedUUID.uuidString)")
    }

    func connectToPeripheral(_ peripheral: CBPeripheral) {
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
        print("Attempting to connect to peripheral: \(peripheral.name ?? "unknown device")")

        // Start the connection timeout timer
        startConnectionTimer(for: peripheral)
    }

    func selectPeripheral(_ peripheral: CBPeripheral) {
        selectedPeripheral = peripheral
        print("Selected peripheral: \(peripheral.name ?? "unknown device")")
    }

    // MARK: - Connection Timeout Handling

    private func startConnectionTimer(for peripheral: CBPeripheral) {
        connectionTimer?.invalidate()
        connectionTimer = Timer.scheduledTimer(withTimeInterval: connectionTimeout, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            if peripheral.state != .connected {
                print("Connection to \(peripheral.name ?? "unknown device") timed out.")
                self.centralManager.cancelPeripheralConnection(peripheral)
                self.connectionFailed = true // Trigger the alert
            }
        }
    }

    private func stopConnectionTimer() {
        connectionTimer?.invalidate()
        connectionTimer = nil
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth is powered on.")
            isBluetoothUnavailable = false
        } else {
            print("Bluetooth is not available.")
            isBluetoothUnavailable = true
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredDevices.append(peripheral)
            print("Discovered peripheral: \(peripheral.name ?? "unknown device")")
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "unknown device")")

        // Stop the connection timer
        stopConnectionTimer()

        // Ensure the peripheral is actually connected before adding it to the connectedDevices list
        if peripheral.state == .connected {
            connectedDevices.append(peripheral)
        }

        // Remove the peripheral from the discoveredDevices list
        discoveredDevices.removeAll { $0.identifier == peripheral.identifier }

        // Discover services after connecting
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "unknown device"): \(String(describing: error))")
        connectionFailed = true // Trigger the alert
        stopConnectionTimer()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.name ?? "unknown device"): \(String(describing: error))")
        connectedDevices.removeAll { $0.identifier == peripheral.identifier }
        if peripheral.identifier == selectedPeripheral?.identifier {
            selectedPeripheral = nil
        }
        scanForConnectedDevices()
    }


    // MARK: - CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }

        if let services = peripheral.services {
            for service in services {
                if service.uuid == serviceUUID {
                    print("Discovered service: \(service.uuid)")

                    // Discover characteristics for the service
                    peripheral.discoverCharacteristics([writeUUID], for: service)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }

        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                print("Discovered characteristic: \(characteristic.uuid)")

                // Handle write characteristic
                if characteristic.uuid == writeUUID {
                    print("Write characteristic discovered.")
                }
            }
        }
    }

    // MARK: - Send Configuration

    func sendConfig(_ config: Config) {
        guard let peripheral = selectedPeripheral else {
            print("No peripheral selected.")
            return
        }

        var byteArray = [UInt8]()
        byteArray.append(config.deadzone)
        byteArray.append(contentsOf: config.up_report)
        byteArray.append(config.up_identPerRev)
        byteArray.append(config.up_transport)
        byteArray.append(contentsOf: config.dn_report)
        byteArray.append(config.dn_identPerRev)
        byteArray.append(config.dn_transport)
        print(byteArray)

        if let services = peripheral.services {
            for service in services {
                if service.uuid == serviceUUID, let characteristics = service.characteristics {
                    for characteristic in characteristics {
                        if characteristic.uuid == writeUUID {
                            peripheral.writeValue(Data(byteArray), for: characteristic, type: .withResponse)
                            print("Configuration sent to \(peripheral.name ?? "unknown device")")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Firmware upgrade

    func upgradeDidStart(controller: any iOSMcuManagerLibrary.FirmwareUpgradeController) {
        print("Start")
        firmwareUpgradeState = "Upgrade started"
    }

    func upgradeStateDidChange(from previousState: FirmwareUpgradeState, to newState: FirmwareUpgradeState) {
        firmwareUpgradeState = "\(newState)"
    }

    func upgradeDidComplete() {
        print("Done")
        firmwareUpgradeState = "Upgrade completed"
    }

    func upgradeDidFail(inState state: iOSMcuManagerLibrary.FirmwareUpgradeState, with error: any Error) {
        print("Failed")
        firmwareUpgradeState = "Upgrade failed: \(error.localizedDescription)"
    }

    func upgradeDidCancel(state: iOSMcuManagerLibrary.FirmwareUpgradeState) {
        print("Cancel")
        firmwareUpgradeState = "Upgrade canceled"
    }

    func uploadProgressDidChange(bytesSent: Int, imageSize: Int, timestamp: Date) {
        // Update progress
        let progress = Double(bytesSent) / Double(imageSize) * 100.0
        firmwareUpgradeProgress = progress

        // Calculate bytes uploaded since the last timestamp
        let bytesSinceLastUpdate = bytesSent - totalBytesUploaded
        totalBytesUploaded = bytesSent

        // Calculate the time elapsed since the last update
        let timeElapsed = timestamp.timeIntervalSince(uploadTimestamp)
        uploadTimestamp = timestamp

        // Calculate upload speed in KB/s (kilobytes per second)
        if timeElapsed > 0 {
            let uploadSpeedInKB = Double(bytesSinceLastUpdate) / 1024 / timeElapsed // Convert bytes to kilobytes
            firmwareUploadSpeed = String(format: "%.2f KB/s", uploadSpeedInKB)
        }

        // Debugging: Log upload speed
        print("Upload Progress: \(progress)%")
        print("Upload Speed: \(firmwareUploadSpeed)")
    }

    // MARK: - McuMgrLogDelegate
    func log(_ msg: String, ofCategory category: iOSMcuManagerLibrary.McuMgrLogCategory, atLevel level: iOSMcuManagerLibrary.McuMgrLogLevel) {
        print(msg)
    }

    func minLogLevel() -> iOSMcuManagerLibrary.McuMgrLogLevel {
        return .info
    }

    // MARK: - Start Firmware Upgrade
    func startFirmwareUpgrade(with firmwareURL: URL?) {
        guard let cbPeripheral = selectedPeripheral else {
            print("No connected peripheral to upgrade firmware.")
            firmwareUpgradeState = "No connected device"
            return
        }

        guard let firmwareURL = firmwareURL else {
            print("No firmware file selected.")
            firmwareUpgradeState = "No firmware file selected"
            return
        }

        let firmwareUpgradeConfig = FirmwareUpgradeConfiguration(
            estimatedSwapTime: 0.0,
            eraseAppSettings: false,
            pipelineDepth: 1,
            byteAlignment: .eightByte,
            reassemblyBufferSize: 4,
            upgradeMode: .uploadOnly,
            bootloaderMode: .unknown
        )

        do {
            let bleTransport = McuMgrBleTransport(cbPeripheral)
            let dfuManager = FirmwareUpgradeManager(transport: bleTransport, delegate: self)
            dfuManager.logDelegate = self
            let package = try McuMgrPackage(from: firmwareURL)

            firmwareUpgradeState = "Starting..."
            try dfuManager.start(package: package, using: firmwareUpgradeConfig)
        } catch {
            print("Failed to initialize firmware upgrade: \(error)")
            firmwareUpgradeState = "Failed to start"
        }
    }
}

// MARK: - Config Struct
struct Config {
    var deadzone: UInt8 = 0
    var up_report: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]
    var up_identPerRev: UInt8 = 30
    var up_transport: UInt8 = 0
    var dn_report: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]
    var dn_identPerRev: UInt8 = 30
    var dn_transport: UInt8 = 0
}
