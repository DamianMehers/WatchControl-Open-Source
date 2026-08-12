//
//  RemoteControlView.swift
//  WatchControl.WatchOS Watch App
//
//  Created by Damian Mehers on 02.04.23.
//

import SwiftUI

struct RemoteControlView: View {
    @ObservedObject var crownHandler = CrownHandler.shared
    @ObservedObject var communicator = TheSender.shared
    @ObservedObject var keychainHandler  = KeychainHandler.shared
    
    var body: some View {
        VStack {
            if communicator.connected {
                Text("WatchControl \(Util.getVersion())")
                    .font(.system(size: 8))
                    .opacity(0.5)
                    .lineLimit(2)
                HStack {
                    NavigationLink(destination: MouseControlView()) {
                        Label("Lightning", systemImage: "computermouse").labelStyle(.iconOnly)
                    }
                    .layoutPriority(1)
                    Spacer()
                        .layoutPriority(1)
                    Button(action: communicator.muteUnmute) {
                        Image(systemName: crownHandler.showQuieter ? "speaker.minus" : crownHandler.showLouder ? "speaker.plus" : crownHandler.speakerImage)
                    }
                    .layoutPriority(1)
                }
                .focusable(true)
                .digitalCrownRotation(
                    $crownHandler.crownValue,
                    from: 0.0,
                    through: 100000,
                    by: 1,
                    sensitivity: .medium,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )
            }
            Spacer()
            
            Text(keychainHandler.selectedServerName)
                .task {
                    await keychainHandler.load()
                    let selected = keychainHandler.selectedServerName
                    if !selected.isEmpty,
                       let _ = keychainHandler.mapping[selected] {
                        TheSender.shared.start()
                    }
                }
                .onChange(of: keychainHandler.selectedServerName) { newValue in
                    Log.d("Detected selectedServerName to \(newValue)")
                    Log.d("Detected selectedServerName to \(newValue)")
                    if let macInfo = keychainHandler.mapping[newValue] {
                        Log.d("Starting sender for \(newValue): \(macInfo.name)")
                        TheSender.shared.start()
                    } else {
                        Log.d("Don't have keycnain info for \(newValue)")
                    }
                }
            if communicator.connected {
                HStack {
                    Button(action: communicator.previous) {
                        Image(systemName: "backward")
                    }
                    Button(action: communicator.playPause) {
                        Image(systemName: "playpause")
                    }
                    Button(action: communicator.next) {
                        Image(systemName: "forward")
                    }
                }
            } else {
                Text(communicator.text)
                ProgressView()
            }
            Spacer()
        }
    }
}
