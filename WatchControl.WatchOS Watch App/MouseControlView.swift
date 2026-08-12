//
//  MouseControlView.swift
//  WatchControl.WatchOS Watch App
//
//  Created by Damian Mehers on 08.06.23.
//

import SwiftUI
import Combine

struct MouseControlView: View {
    static let initialCrownValue = 5000.0
    @ObservedObject var communicator = TheSender.shared
    @State var isDragging = false
    @State var crownValue = Self.initialCrownValue
    @State var oldCrownValue: Double = initialCrownValue
    @State var longPressTask: Task<Void, Never>? = nil
    var drag: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { v in
                cancelLongPress()
            }
            .onEnded { pos in
                cancelLongPress()
                self.isDragging = false
                communicator.moveMouse(x: pos.translation.width, y: pos.translation.height)
            }
    }
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                Text("Tap, drag, long-press to control the mouse. Scroll using the digital crown...")
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            Spacer()
        }
        .background(Color.gray)
        .gesture(drag)
        .onTapGesture {
            cancelLongPress()
            communicator.leftMouseClick()
        }
        .onLongPressGesture {
            cancelLongPress()
        }
        onPressingChanged: { v in
            cancelLongPress()
            if v {
                longPressTask = Task {
                    do {
                        try await Task.sleep(for: .seconds(0.5))
                        communicator.rightMouseClick()
                    } catch {
                    }
                }
            }
        }
        .focusable(true)
        .digitalCrownRotation(
            detent: $crownValue,
            from: 0,
            through: Self.initialCrownValue * 2,
            by: 100,
            sensitivity: .high,
            isContinuous: true,
            isHapticFeedbackEnabled: true
        ) { crownEvent in
            let offset = crownValue - oldCrownValue
            if offset == 0 {
                return
            }
            communicator.scroll(amount: offset)
            oldCrownValue = crownValue
        }
    }
    
    func cancelLongPress() {
        longPressTask?.cancel()
        longPressTask = nil
    }
}
