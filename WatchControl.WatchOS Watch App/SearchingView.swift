//
//  SearchingView.swift
//  WatchControl
//
//  Created by Damian Mehers on 02.04.23.
//

import SwiftUI

struct SearchingView: View {
    @ObservedObject var keychainHandler = KeychainHandler.shared
    var body: some View {
        ScrollView {
            VStack {
                Text("Looking for Macs...")
                    .font(.title3)
                Text("Ensure both your Watch and Mac are both signed into the same iCloud account in Settings, and that KeyChain sync is enabled.\n\nYou'll need to install the WatchControl Mac app on your Mac(s)")
                    .font(.caption2)
                ProgressView()
                    .padding(4)
            }
        }
        .task {
            do {
                while keychainHandler.servers.isEmpty {
                    await keychainHandler.load()
                    try await Task.sleep(for: .seconds(3))
                }
            } catch {
            }
        }
    }
}
