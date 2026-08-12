//
//  Communicator.swift
//  WatchControl.WatchOS Watch App
//
//  Created by Damian Mehers on 01.04.23.
//

import Foundation
import CoreBluetooth
import WatchKit



class TheSender: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject {
    var serviceUUID: CBUUID?
    var macInfo: MacInfo? {
        KeychainHandler.shared.selectedMac
    }
    var centralManager: CBCentralManager?
    var connectedPeripheral: CBPeripheral?
    var controlCharacteristic: CBCharacteristic?
    var statusCharacteristic: CBCharacteristic?
    
    @MainActor
    @Published var text: String = ""
    
    @MainActor
    @Published var connected = false
    
    @MainActor
    @Published var status: StatusResponse?
    
    @MainActor
    @Published var macVolume: Double = -1
    
    static let shared = TheSender()
    
    private override init() { }
    
    func setText(_ text: String) {
        Log.d(text)
        DispatchQueue.main.async {
            self.text = text
        }
    }
    
    @MainActor
    func stop() {
        Log.d("Stopping")
        if let connectedPeripheral = connectedPeripheral,
           let centralManager = centralManager {
            centralManager.cancelPeripheralConnection(connectedPeripheral)
        }
        
        setText("Stopped")
        serviceUUID = nil
        centralManager = nil
        connectedPeripheral = nil
        controlCharacteristic = nil
        connected = false
    }
    
    @MainActor
    func start() {
        guard let macInfo = self.macInfo else {
            return
        }
        if let peripheralName = connectedPeripheral?.name,
           peripheralName == macInfo.name,
           self.macInfo?.name == macInfo.name {
            Log.d("Already connected")
            return
        }
        
        stop()
        Log.d("Starting for \(macInfo.name)")
        if let connectedPeripheral = connectedPeripheral,
           let centralManager = centralManager {
            centralManager.cancelPeripheralConnection(connectedPeripheral)
        }
        connectedPeripheral = nil
        connected = false
        controlCharacteristic = nil
        
        // Initialize the central manager
        serviceUUID = CBUUID(string: macInfo.serviceId)
        
        if(centralManager?.state == .poweredOn && centralManager?.isScanning == true) {
            Log.d("Already have a centralManager so stopping it and scanning")
            centralManager?.scanForPeripherals(withServices: [serviceUUID!], options: nil)
        } else {
            Log.d("Initializing central manager")
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Log.d("centralManagerDidUpdateState: \(central.state)")
        guard let serviceUUID = serviceUUID else {
            Log.d("centralManagerDidUpdateState but no serviceUUID")
            return
        }
        guard let macInfo = macInfo else {
            Log.d("centralManagerDidUpdateStatebut no macInfo")
            return
        }
        switch central.state {
            case .poweredOn:
                // Scan for peripherals when Bluetooth is powered on
                Log.d("Scanning")
                setText("Searching for \(macInfo.name)")
                central.scanForPeripherals(withServices: [serviceUUID], options: nil)
            default:
                break
        }
    }
    
    func centralManager(_ central:CBCentralManager, didFailToConnect: CBPeripheral, error: Error?) {
        Log.d("centralManager didFailToConnect peripheral: \(String(describing: error))")
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState: [String : Any]) {
        Log.d("centralManager willRestoreState: \(willRestoreState)")
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        Log.d("centralManager didDiscover peripheral \(peripheral.name ?? "Unknown")")
        guard let macInfo = macInfo else {
            Log.d("didDiscover peripheral but no macInfo")
            return
        }
        
        guard let peripheralName = peripheral.name else {
            Log.d("centralManager didDiscover Can't get peripheral name")
            return
        }
        
        guard peripheralName == macInfo.name else {
            Log.d("centralManager didDiscover Peripheral \(peripheralName) does not match mac we are looking for: \(macInfo.name)")
            return
        }
        
        setText("Found \(macInfo.name), connecting ...")
        // Connect to the discovered peripheral
        connectedPeripheral = peripheral
        centralManager?.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Log.d("centralManager didConnect peripheral")
        guard let serviceUUID = serviceUUID else {
            Log.d("didConnect but no serviceUUID")
            return
        }
        guard let macInfo = macInfo else {
            Log.d("didConnect but no macInfo")
            return
        }
        guard let peripheralName = peripheral.name else {
            Log.d("centralManager didConnect Can't get peripheral name")
            return
        }
        
        guard peripheralName == macInfo.name else {
            Log.d("centralManager didConnect Peripheral \(peripheralName) does not match mac we are looking for: \(macInfo.name)")
            return
        }

        setText("Connected to \(macInfo.name), discovering services ...")
        // Discover services for the connected peripheral
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Log.d("peripheral didDiscoverServices")
        guard let services = peripheral.services else {
            Log.d("peripheral didDiscoverServices but no services")
            return
        }
        guard let macInfo = macInfo else {
            Log.d("peripheral didDiscoverServices but no macInfo")
            return
        }

        guard let peripheralName = peripheral.name else {
            Log.d("centralManager didDiscoverServices Can't get peripheral name")
            return
        }
        
        guard peripheralName == macInfo.name else {
            Log.d("centralManager didDiscoverServices Peripheral \(peripheralName) does not match mac we are looking for: \(macInfo.name)")
            return
        }

        
        for service in services {
            if service.uuid == serviceUUID {
                // Discover characteristics for the service
                peripheral.discoverCharacteristics([Characteristic.control, Characteristic.status], for: service)
                setText("Discovered \(macInfo.name) services, discovering characteristics")
                return
            }
        }
        setText("Not not find expected service on \(macInfo.name)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        Log.d("peripheral didDiscoverCharacteristicsFor service")
        guard let characteristics = service.characteristics else {
            Log.d("peripheral didDiscoverCharacteristicsFor but no characteristics")
            return
        }
        guard let macInfo = macInfo else {
            Log.d("peripheral didDiscoverCharacteristicsFor but no macInfo")
            return
        }

        guard let peripheralName = peripheral.name else {
            Log.d("centralManager didDiscoverCharacteristicsFor Can't get peripheral name")
            return
        }
        
        guard peripheralName == macInfo.name else {
            Log.d("centralManager didDiscoverCharacteristicsFor Peripheral \(peripheralName) does not match mac we are looking for: \(macInfo.name)")
            return
        }

        
        guard service.uuid == serviceUUID else {
            setText("Received peripherals for old service on \(macInfo.name)")
            Log.d("Received peripherals for old service")
            return
        }
        
        for characteristic in characteristics {
            Log.d("examining characteristic \(characteristic.uuid)")
            if characteristic.uuid == Characteristic.control {
                Log.d("Have control characteristic")
                controlCharacteristic = characteristic
                write(kind: .nop)
                DispatchQueue.main.async {
                    self.connected = true
                }
            }
            if characteristic.uuid == Characteristic.status {
                Log.d("Have status characteristic")
                peripheral.setNotifyValue(true, for: characteristic)
                statusCharacteristic = characteristic
                requestStatus()
            }
        }
    }
    
    @MainActor
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard let macInfo = macInfo else {
            Log.d("didUpdateValueFor but no macInfo")
            return
        }

        
        guard let peripheralName = peripheral.name else {
            Log.d("peripheral didUpdateValueFor  Can't get peripheral name")
            return
        }
        
        guard peripheralName == macInfo.name else {
            Log.d("peripheral didUpdateValueFor  Peripheral \(peripheralName) does not match mac we are looking for: \(macInfo.name)")
            return
        }

        
        Log.d("Received characteristic update: \(characteristic).  Is status: \( characteristic == statusCharacteristic)")
        if characteristic == statusCharacteristic {
            if let data = characteristic.value,
               let status = try? JSONDecoder().decode(StatusResponse.self, from: data) {
                self.status = status
                CrownHandler.shared.macVolumeUpdated(volume: status.volume, muted: status.muted)
            }
        }
    }
    
    func requestStatus() {
        if let connectedPeripheral = connectedPeripheral,
           let statusCharacteristic = statusCharacteristic {
            connectedPeripheral.readValue(for: statusCharacteristic)
        }

    }
    
    private func write(kind: Command.CommandKind, x: Double? = nil, y: Double? = nil) {
        guard let peripheral = connectedPeripheral else {
            Log.d("write but no connectedPeripheral")
            return
        }
        
        guard let macInfo = macInfo else {
            Log.d("write but no macInfo")
            return
        }

        
        guard let peripheralName = peripheral.name else {
            Log.d("write Can't get peripheral name")
            return
        }
        
        guard peripheralName == macInfo.name else {
            Log.d("write Peripheral \(peripheralName) does not match mac we are looking for: \(macInfo.name)")
            return
        }
        
//        Log.d("Requested to write \(kind)")
        if let characteristic = controlCharacteristic {
//            Log.d("Writing \(kind)")
            let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            let version = Double(versionString ?? "-1")
            let command = Command(id: UUID().uuidString,
                                  sender: WKInterfaceDevice.current().name,
                                  secret: macInfo.secret,
                                  kind: kind,
                                  watchAppVersion: version,
                                  x: x,
                                  y: y)
            let plainData = try! JSONEncoder().encode(command)
            guard let encryptedData = CryptUtils.encrypt(data: plainData, key: macInfo.secret) else {
                Log.d("Can't encrypt data")
                return
            }
            peripheral.writeValue(encryptedData, for: characteristic, type: .withResponse)
        }
    }
    
    func playPause() {
        write(kind: .playPause)
    }
    
    func louder() {
        write(kind: .louder)
    }
    
    func quieter() {
        write(kind: .quieter)
    }
    
    func next() {
        write(kind: .next)
    }
    
    func previous() {
        write(kind: .previous)
    }
    
    func muteUnmute() {
        write(kind: .muteUnmute)
    }
    
    func leftMouseClick() {
        write(kind: .leftMouseClick)
    }
    
    func rightMouseClick() {
        write(kind: .rightMouseClick)
    }
    
    func moveMouse(x: Double, y: Double) {
        write(kind: .mouseMove, x: x, y: y)
    }
    
    func scroll(amount: Double) {
        write(kind: .scroll, y: amount)
    }
}
