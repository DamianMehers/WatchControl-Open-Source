//
//  ServersView.swift
//  WatchControl.WatchOS Watch App
//
//  Created by Damian Mehers on 02.04.23.
//

import SwiftUI

struct ServersView: View {
    @ObservedObject var keychainHandler = KeychainHandler.shared
    var body: some View {
        VStack {
            Spacer()
            Picker("Mac", selection: keychainHandler.$selectedServerName) {
                ForEach(keychainHandler.servers, id: \.self) {
                    Text($0)
                }
            }
            Spacer()
            HStack {
                Button {
                    Task {
                        TheSender.shared.stop()
                        await keychainHandler.load()
                        TheSender.shared.start()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise.circle")
                }
                .frame(width: 32)
                Spacer()
                Button {
                    Task {
                        TheSender.shared.stop()
                        await keychainHandler.deleteServer(serverName: keychainHandler.selectedServerName)
                    }
                } label: {
                    Image(systemName: "trash.slash")
                }
                .disabled(keychainHandler.servers.isEmpty)
                .frame(width: 32)
            }
        }
    }
}

struct ServersView_Previews: PreviewProvider {
    static var previews: some View {
        ServersView()
    }
}
