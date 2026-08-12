//
//  TheListener.swift
//  WatchMacMedia.MacOS
//
//  Created by Damian Mehers on 01.04.23.
//

import Foundation
import Security
import CoreBluetooth
import SwiftUI
import ApplicationServices
import Combine
import AudioToolbox
import CoreAudio

class TheListener: NSObject, CBPeripheralManagerDelegate, ObservableObject {
    static let shared = TheListener()
    
    private override init() {}
    @AppStorage("ServiceUUID")
    var serviceUUIDString: String = CBUUID().uuidString
    
    @AppStorage("Secret")
    var secret: String = Int64.random(in: Int64.min...Int64.max).description
    
    var serviceUUID : CBUUID { CBUUID(string: serviceUUIDString)}
    
    var peripheralManager: CBPeripheralManager?
    
    var controlCharacteristic:  CBMutableCharacteristic?
    var statusCharacteristic:  CBMutableCharacteristic?
    
    @Published
    @MainActor
    var status = "Not running"
    
    @Published
    @MainActor
    var running = false
    
    private var storeCancellable : AnyCancellable?
    
    private func getDefaultOutputDeviceID() -> AudioObjectID {
        var defaultOutputDeviceID = kAudioObjectUnknown
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var propertySize = UInt32(MemoryLayout<AudioObjectID>.size)
        let result = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &defaultOutputDeviceID
        )
        
        if kAudioHardwareNoError != result {
            Log.d("Cannot find default output device, error: \(result)")
        }
        
        return defaultOutputDeviceID
    }
    
    private func getVolumeAddress() -> AudioObjectPropertyAddress{
        AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)
    }
    
    private func getMuteAddress() -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)
    }
    
    @MainActor
    private var statusResponse: StatusResponse {
        var volume: Double?
        var muted: Bool? = nil
        
        let defaultDeviceID = getDefaultOutputDeviceID()
        if defaultDeviceID != kAudioObjectUnknown {
            var volumeAddress = getVolumeAddress()
            var volumeRead = Float32(-1)
            var volumeSize = UInt32(MemoryLayout.size(ofValue: volumeRead))
            let volumeResult = AudioObjectGetPropertyData(defaultDeviceID, &volumeAddress, 0, nil, &volumeSize, &volumeRead)
            if volumeResult == 0 {
                volume = Double(volumeRead)
            }
            
            var mute: UInt32 = 0
            var muteSize = UInt32(MemoryLayout<UInt32>.size)
            var muteAddress = getMuteAddress()
            let muteResult = AudioObjectGetPropertyData(defaultDeviceID, &muteAddress, 0, nil, &muteSize, &mute)
            if muteResult == 0 {
                muted = mute == 1
            }
            Log.d("volumeResult: \(volumeResult) and volume: \(volume?.description ?? "unknown")")
            Log.d("muteResult: \(muteResult) and mute: \(mute) and muted: \(muted?.description ?? "unknown")")
        }
        
        Log.d("Volume is \(volume?.description ?? "unknown") and muted: \(muted?.description ?? "unknown")")
        let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let version = Double(versionString ?? "-1")
        return StatusResponse(licenseStatus: Store.shared.status, volume:volume, muted: muted, macAppVersion: version)
    }
    
    private func setStatus(_ running: Bool, status: String? = nil ) {
        DispatchQueue.main.async {
            self.running = running
            self.status = status ?? (running ? "Listening ..." : "Not running");
        }
    }
    
    func start() {
        // Initialize the peripheral manager
        let macName = getCurrentMacName()
        Log.d("Starting ... mac name is \(macName)")
        Log.d("Path: \(Bundle.main.bundlePath)")
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        let macInfo = MacInfo(serviceId: serviceUUIDString, name: macName, lastUpdate: Date(), secret: secret, version: Util.getVersion())
        DispatchQueue.global().async {
            KeyStore.shared.store(macInfo: macInfo)
        }
        storeCancellable = Store.shared.$status.sink { s in
            Log.d("Sending a status update because store status changed")
            self.sendStatusUpdate()
        }
        
//        Task {
//            while true {
//                try? await Task.sleep(for: .seconds(3))
//                Log.d("Tapping mouse")
//                scroll(x: 100)
//            }
//                
//        }
        
    }
    
    func getCurrentMacName() -> String {
        return Host.current().localizedName ?? "My Mac"
    }
    
    // MARK: - CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
            case .poweredOn:
                // Setup and start advertising when Bluetooth is powered on
                Log.d("Powered on")
                setupPeripheralAndStartAdvertising()
            default:
                break
        }
    }
    
    func setupPeripheralAndStartAdvertising() {
        // Create the service
        let service = CBMutableService(type: serviceUUID, primary: true)
        let properties: CBCharacteristicProperties =  [.read, .write, .notify]
        let permissions: CBAttributePermissions = [ .writeable, .readable]
        
        controlCharacteristic = CBMutableCharacteristic(type: Characteristic.control, properties: properties, value: nil, permissions: permissions)
        
        statusCharacteristic = CBMutableCharacteristic(type: Characteristic.status, properties: properties, value: nil, permissions: permissions)
        
        service.characteristics = [controlCharacteristic!, statusCharacteristic!]
        
        // Add the service to the peripheral manager
        peripheralManager?.add(service)
        
        // Start advertising
        Log.d("Starting advertising")
        setStatus(true)
        peripheralManager?.startAdvertising([
            CBAdvertisementDataLocalNameKey: getCurrentMacName() + " WatchControl",
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID]
        ])
    }
    
    
    @MainActor
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if request.characteristic.uuid == Characteristic.status {
            let status = statusResponse
            guard let data = try? JSONEncoder().encode(status) else {
                Log.d("Can't encode status data")
                return
            }
            
            request.value = data
            peripheralManager?.respond(to: request, withResult: .success)
        } else {
            peripheralManager?.respond(to: request, withResult: .attributeNotFound)
        }
    }
    
    func sendStatusUpdate() {
        // Give previous command time to execute
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            // Your code here
            if let peripheralManager = self.peripheralManager,
               let statusCharacteristic = self.statusCharacteristic {
                let status = self.statusResponse
                guard let data = try? JSONEncoder().encode(status) else {
                    Log.d("Can't encode status data")
                    return
                }
                peripheralManager.updateValue(data, for: statusCharacteristic, onSubscribedCentrals: nil)
            }
        }
    }
    
    
    @MainActor func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        Log.d("peripheralManager didReceiveWrite")
        
        if Store.shared.status == .noTrial || Store.shared.status == .expired {
            showPurchaseView()
            return
        }
        
        for request in requests {
            
            guard request.characteristic.uuid == Characteristic.control else {
                Log.d("Wrong characteristic")
                peripheralManager?.respond(to: request, withResult: .attributeNotFound)
                continue
            }
            
            guard let encryptedData = request.value,
                  let data = CryptUtils.decrypt(data: encryptedData, key: secret),
                  let command = try? JSONDecoder().decode(Command.self, from: data) else {
                Log.d("Can't get command")
                peripheralManager?.respond(to: request, withResult: .insufficientAuthorization)
                continue
            }
            
            guard command.secret == secret else {
                Log.d("Secret is wrong")
                peripheralManager?.respond(to: request, withResult: .insufficientAuthorization)
                continue
            }
            
            Log.d("Command is \(command.kind) from \(command.sender)")
            peripheral.respond(to: request, withResult: .success)
            switch command.kind {
                case .playPause:
                    playPause()
                case .louder:
                    louder()
                    sendStatusUpdate()
                case .quieter:
                    quieter()
                    sendStatusUpdate()
                case .next:
                    next()
                case .previous:
                    previous()
                case .nop:
                    Log.d("Not doing anything")
                case .muteUnmute:
                    muteUnmute()
                    sendStatusUpdate()
                case .mouseMove:
                    if let x = command.x,
                       let y = command.y {
                        moveMouse(x, y)
                    }
                    
                case .leftMouseClick:
                    mouseTap(left: true)
                case .rightMouseClick:
                    mouseTap(left: false)
                case .scroll:
                    if let y = command.y {
                        scroll(y: y)
                    }
            }
        }
    }
    
    let NX_KEYTYPE_SOUND_UP: UInt32 = 0
    let NX_KEYTYPE_SOUND_DOWN: UInt32 = 1
    let NX_KEYTYPE_PLAY: UInt32 = 16
    let NX_KEYTYPE_NEXT: UInt32 = 17
    let NX_KEYTYPE_PREVIOUS: UInt32 = 18
    let NX_KEYTYPE_FAST: UInt32 = 19
    let NX_KEYTYPE_REWIND: UInt32 = 20
    let NX_UP_ARROW_KEY: UInt32 = 8
    let NX_KEYTYPE_MUTE: UInt32 = 7
    
    func muteUnmute() {
        HIDPostAuxKey(key:NX_KEYTYPE_MUTE)
    }
    
    
    func playPause() {
        HIDPostAuxKey(key:NX_KEYTYPE_PLAY)
    }
    
    func louder() {
        HIDPostAuxKey(key:NX_KEYTYPE_SOUND_UP)
    }
    
    func quieter() {
        HIDPostAuxKey(key:NX_KEYTYPE_SOUND_DOWN)
    }
    
    func next() {
        HIDPostAuxKey(key:NX_KEYTYPE_FAST)
        //        HIDPostAuxKey(key:NX_KEYTYPE_NEXT)
    }
    
    func previous() {
        HIDPostAuxKey(key:NX_KEYTYPE_REWIND)
        //        HIDPostAuxKey(key:NX_KEYTYPE_PREVIOUS)
    }
    
    func up() {
        HIDPostAuxKey(key:NX_UP_ARROW_KEY)
    }
    
    func hasAccessibilityAccess() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        return accessEnabled
    }
    
    func moveMouse(_ x: Double, _ y: Double) {
        let currentPos = CGEvent(source: nil)?.location ?? .zero
        let newPos = CGPoint(x: currentPos.x + x, y: currentPos.y + y)

        let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: newPos, mouseButton: .left)
        moveEvent?.post(tap: .cghidEventTap)
    }
    
    func scroll(y: Double) {
        let scrollEvent = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: Int32(y), wheel2: 0, wheel3: 0)

        scrollEvent?.post(tap: CGEventTapLocation.cghidEventTap)
    }

    func mouseTap(left: Bool) {
        let currentPos = CGEvent(source: nil)?.location ?? .zero
        let mouseDownType = left ? CGEventType.leftMouseDown : CGEventType.rightMouseDown
        let mouseUpType = left ? CGEventType.leftMouseUp : CGEventType.rightMouseUp
        let mouseButton = left ? CGMouseButton.left : CGMouseButton.right
        
        let mouseDown = CGEvent(mouseEventSource: nil, mouseType: mouseDownType, mouseCursorPosition: currentPos, mouseButton: mouseButton)
        let mouseUp = CGEvent(mouseEventSource: nil, mouseType: mouseUpType, mouseCursorPosition: currentPos, mouseButton: mouseButton)

        mouseDown?.post(tap: .cghidEventTap)
        mouseUp?.post(tap: .cghidEventTap)
    }

    
    func HIDPostAuxKey(key: UInt32) {
        func doKey(down: Bool) {
            let flags = NSEvent.ModifierFlags(rawValue: (down ? 0xa00 : 0xb00))
            let data1 = Int((key<<16) | (down ? 0xa00 : 0xb00))
            
            let ev = NSEvent.otherEvent(with: NSEvent.EventType.systemDefined,
                                        location: NSPoint(x:0,y:0),
                                        modifierFlags: flags,
                                        timestamp: 0,
                                        windowNumber: 0,
                                        context: nil,
                                        subtype: 8,
                                        data1: data1,
                                        data2: -1
            )
            let cev = ev?.cgEvent
            cev?.post(tap: CGEventTapLocation.cghidEventTap)
        }
        doKey(down: true)
        doKey(down: false)
    }
}
