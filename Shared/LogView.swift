//
//  LogView.swift
//  WatchControl
//
//  Created by Damian Mehers on 02.04.23.
//

import SwiftUI

struct LogView: View {
    @ObservedObject var log = Log.shared
    @State var feedback = ""
    var body: some View {
        VStack {
            if log.working {
                ProgressView("Sending ...")
            } else {
                VStack {
                    Text("WatchControl \(Util.getVersion())\nSupport/Feedback")
                        .font(.caption)
                    ScrollView {
                        TextField("Enter feedback here", text: $feedback)
                        Button(action: {() in
                            Task {
                                await log.submit(feedback: feedback)
                            }
                        }) {
                            VStack {
                                Text("Send to developer")
                            }
                        }
                        Text("This log will be included")
                            .font(.caption2)
                        .alert(isPresented: $log.haveMessage) {
                            Alert(
                                title: Text("Submitted"),
                                message: Text(log.message)
                                    .font(.caption)
                            )
                        }
                        VStack(alignment: .leading) {
                            ForEach(log.entries) { e in
                                Text(e.text)
                                    .font(.system(size: 8))
                                    .multilineTextAlignment(.leading)
                                    .monospaced()
                                    .padding(0)
                            }
                        }
                        .padding(0)
                    }
                    .padding(0)
                }
            }
        }
    }
}

struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        LogView()
    }
}
