//
//  CrownHandler.swift
//  WatchControl.WatchOS Watch App
//
//  Created by Damian Mehers on 01.04.23.
//

import Foundation
import Combine

class CrownHandler: ObservableObject {
    @Published var crownValue: Double = 50000.0
    @Published var showLouder = false
    @Published var showQuieter = false
    @Published var speakerImage = "speaker"
    private var oldValue = 50000.0
    private var cancellables = [AnyCancellable]()
    private var spinning = false
    
    public static let shared = CrownHandler()
    
    private init() {
        var cancelable = $crownValue
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.crownDidStopRotating()
            }
        cancellables.append((cancelable))
        
        cancelable = $crownValue
            .sink { [weak self] newValue in
                Log.d("newValue: \(newValue)")
                if let handler = self {
                    
                    Log.d("newValue: \(newValue)")
                    if abs(newValue - handler.oldValue) < 2 {
                        return
                    }
                    
                    handler.showLouder = newValue > handler.oldValue
                    handler.showQuieter = newValue < handler.oldValue
                    
                    handler.oldValue = newValue
                    if (handler.showLouder || handler.showQuieter) {
                        if handler.showLouder {
                            TheSender.shared.louder()
                        } else if handler.showQuieter {
                            TheSender.shared.quieter()
                        }
                    }
                }
            }
        cancellables.append((cancelable))
    }
    
    @MainActor
    func macVolumeUpdated(volume: Double?, muted: Bool?) {
        guard let volume = volume,
              let muted = muted else {
            return
        }
        Log.d("Muted: \(muted) Volume: \(volume)")
        if muted {
            speakerImage = "speaker.slash"
        } else if volume < 0.25 {
            speakerImage = "speaker"
        } else if volume <= 0.5 {
            speakerImage = "speaker.wave.1"
        } else if volume <= 0.75 {
            speakerImage = "speaker.wave.2"
        } else {
            speakerImage = "speaker.wave.3"
        }
    }
    
    private func crownDidStopRotating() {
        Log.d("Crown stopped rotating. Final value: \(crownValue)")
        oldValue = crownValue
        showLouder = false
        showQuieter = false
        spinning = false
    }
}
