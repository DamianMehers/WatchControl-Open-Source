//
//  WatchControl_WatchOSApp.swift
//  WatchControl.WatchOS Watch App
//
//  Created by Damian Mehers on 01.04.23.
//

import SwiftUI

@main
struct WatchControl_Watch_App: App {
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
//            MouseControlView()
            ContentView()
                .onChange(of: scenePhase) { phase in
                    Log.d("Phase is now \(scenePhase)")
                    if phase == .background {
                        TheSender.shared.stop()
                    } else if phase == .active {
                        // Use the selected server not the fist one!
                        let selected = KeychainHandler.shared.selectedServerName
                        Log.d("WatchControl_Watch_App selected is \(selected)")
                        if !selected.isEmpty,
                           let macInfo = KeychainHandler.shared.mapping[selected] {
                            Log.d("Found macInfo \(macInfo.name)")
                            TheSender.shared.start()
                        }
                    }
                }
        }
    }
}
