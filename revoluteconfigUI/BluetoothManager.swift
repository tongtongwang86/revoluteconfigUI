import Foundation
import CoreBluetooth
import Combine

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral?

    let advertisedServiceUUID = CBUUID(string: "00001523-1212-efde-1523-785feabcd133")
    let serviceUUID = CBUUID(string: "00000000-0000-0000-0000-003323DE1223")
    let readAngleCharacteristicUUID = CBUUID(string: "00000000-0000-0000-0000-003323DE1224")
    let writeModeCharacteristicUUID = CBUUID(string: "00000000-0000-0000-0000-003323DE1225")
    let writeNumIdentCharacteristicUUID = CBUUID(string: "00000000-0000-0000-0000-003323DE1226")
    let writeDeadZoneCharacteristicUUID = CBUUID(string: "00000000-0000-0000-0000-003323DE1227")
    let writeUpReportCharacteristicUUID = CBUUID(string: "00000000-0000-0000-0000-003323DE1228")
    let writeDownReportCharacteristicUUID = CBUUID(string: "00000000-0000-0000-0000-003323DE1229")

    @Published var uint16Value: UInt16 = 0
    @Published var isConnected: Bool = false
    @Published var availableDevices: [CBPeripheral] = []
    @Published var connectedDevices: [CBPeripheral] = []
    var readTimer: Timer?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScanning() {
        availableDevices.removeAll()
        centralManager.scanForPeripherals(withServices: [advertisedServiceUUID], options: nil)
    }

    func stopScanning() {
        centralManager.stopScan()
    }

    func connect(to peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.peripheral?.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }

    func startReadTimer() {
        readTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(readCharacteristicValue), userInfo: nil, repeats: true)
    }

    func stopReadTimer() {
        readTimer?.invalidate()
        readTimer = nil
    }

    @objc func readCharacteristicValue() {
        if let peripheral = peripheral, let services = peripheral.services {
            for service in services {
                if service.uuid == serviceUUID, let characteristics = service.characteristics {
                    for characteristic in characteristics {
                        if characteristic.uuid == readAngleCharacteristicUUID {
                            peripheral.readValue(for: characteristic)
                        }
                    }
                }
            }
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            scanAndRetrievePairedDevices()
        default:
            print("Bluetooth is not available.")
        }
    }

    func retrievePairedDevice() -> CBPeripheral? {
        let connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: [serviceUUID])
        return connectedPeripherals.first
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if !availableDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            availableDevices.append(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([serviceUUID])
        if !connectedDevices.contains(peripheral) {
            connectedDevices.append(peripheral)
        }
        isConnected = true
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        if let index = connectedDevices.firstIndex(of: peripheral) {
            connectedDevices.remove(at: index)
        }
        self.peripheral = nil
        stopReadTimer()
        startScanning()
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == serviceUUID {
                    peripheral.discoverCharacteristics([
                        readAngleCharacteristicUUID,
                        writeModeCharacteristicUUID,
                        writeNumIdentCharacteristicUUID,
                        writeDeadZoneCharacteristicUUID,
                        writeUpReportCharacteristicUUID,
                        writeDownReportCharacteristicUUID
                    ], for: service)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == readAngleCharacteristicUUID {
                    peripheral.setNotifyValue(true, for: characteristic)
                    startReadTimer()
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value {
            let rawuint16Value = value.withUnsafeBytes { $0.load(as: UInt16.self) }
            let uint16Value = (Int16(rawuint16Value) * -1) + 360
            DispatchQueue.main.async {
                self.uint16Value = UInt16(uint16Value)
            }
        }
    }

    func writeModeReport(byteArray: [UInt8]) {
        let data = Data(byteArray)

        if let peripheral = peripheral, let services = peripheral.services {
            for service in services {
                if service.uuid == serviceUUID, let characteristics = service.characteristics {
                    for characteristic in characteristics {
                        if characteristic.uuid == writeModeCharacteristicUUID {
                            peripheral.writeValue(data, for: characteristic, type: .withResponse)
                        }
                    }
                }
            }
        }
    }
    
    func writeNumIdentReport(byteArray: [UInt8]) {
        let data = Data(byteArray)

        if let peripheral = peripheral, let services = peripheral.services {
            for service in services {
                if service.uuid == serviceUUID, let characteristics = service.characteristics {
                    for characteristic in characteristics {
                        if characteristic.uuid == writeNumIdentCharacteristicUUID {
                            peripheral.writeValue(data, for: characteristic, type: .withResponse)
                        }
                    }
                }
            }
        }
    }
    
    
    func writeDeadZoneReport(byteArray: [UInt8]) {
        let data = Data(byteArray)

        if let peripheral = peripheral, let services = peripheral.services {
            for service in services {
                if service.uuid == serviceUUID, let characteristics = service.characteristics {
                    for characteristic in characteristics {
                        if characteristic.uuid == writeDeadZoneCharacteristicUUID {
                            peripheral.writeValue(data, for: characteristic, type: .withResponse)
                        }
                    }
                }
            }
        }
    }
    
    
    
    func writeDownReport(byteArray: [UInt8]) {
        let data = Data(byteArray)

        if let peripheral = peripheral, let services = peripheral.services {
            for service in services {
                if service.uuid == serviceUUID, let characteristics = service.characteristics {
                    for characteristic in characteristics {
                        if characteristic.uuid == writeDownReportCharacteristicUUID {
                            peripheral.writeValue(data, for: characteristic, type: .withResponse)
                        }
                    }
                }
            }
        }
    }
    
    
    func writeUpReport(byteArray: [UInt8]) {
        let data = Data(byteArray)

        if let peripheral = peripheral, let services = peripheral.services {
            for service in services {
                if service.uuid == serviceUUID, let characteristics = service.characteristics {
                    for characteristic in characteristics {
                        if characteristic.uuid == writeUpReportCharacteristicUUID {
                            peripheral.writeValue(data, for: characteristic, type: .withResponse)
                        }
                    }
                }
            }
        }
    }

    func scanAndRetrievePairedDevices() {
        startScanning()
        if let pairedPeripheral = retrievePairedDevice() {
            connect(to: pairedPeripheral)
        }
    }
}
