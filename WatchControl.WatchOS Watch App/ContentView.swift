//
//  ContentView.swift
//  WatchMacMedia.WatchOS Watch App
//
//  Created by Damian Mehers on 29.03.23.
//

import SwiftUI


struct ContentView: View {
    @ObservedObject var communicator = TheSender.shared
    @ObservedObject var keychainHandler  = KeychainHandler.shared
    //    @ObservedObject var crownHandler = CrownHandler.shared
    @State var pickedServer = ""
    
    var body: some View {
        NavigationStack {
            TabView {
                if keychainHandler.servers.isEmpty {
                    SearchingView()
                        .tag(1)
                } else {
                    RemoteControlView()
                        .tag(1)
                }
                if !keychainHandler.servers.isEmpty {
                    ServersView()
                        .tag(3)
                }
                LogView()
                    .tag(4)
            }
        }
        
    }
}
