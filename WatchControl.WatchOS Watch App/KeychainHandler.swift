//
//  KeychainHandler.swift
//  WatchControl.WatchOS Watch App
//
//  Created by Damian Mehers on 02.04.23.
//

import Foundation
import SwiftUI


class KeychainHandler: ObservableObject {
    
    public static var shared = KeychainHandler()
    
    private init() {}
    
    @MainActor
    @Published
    var servers =  [String]()
    var mapping = [String:MacInfo]()
    
    @AppStorage("selectedServerName")
    public var selectedServerName = ""
    
    var selectedMac: MacInfo? {
        if selectedServerName.isEmpty {
            return nil
        }
        return mapping[selectedServerName]
    }
    
    @MainActor
    func deleteServer(serverName: String) async {
        await KeyStore.shared.clear(name: serverName)
        await load()
    }

    
    @MainActor
    func load() async {
        let infos = await KeyStore.shared.retrieve()
        for info in infos {
            Log.d("Found Keychain Mac: \(info.name), version: \(info.version) last update: \(info.lastUpdate)")
        }
        mapping = infos.reduce(into: [String:MacInfo]()) { result, info in result[info.name] = info}
        servers = Array(infos.map( { $0.name}))
        if !servers.contains(selectedServerName) {
            selectedServerName = ""
        }
        if selectedServerName.isEmpty {
            selectedServerName = servers.first ?? ""
        }
        Log.d("Selected server name: \(selectedServerName)")
    }
    
}
