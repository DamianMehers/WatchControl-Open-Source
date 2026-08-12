//
//  WatchControl_MacApp.swift
//  WatchControl.Mac
//
//  Created by Damian Mehers on 01.04.23.
//

import SwiftUI
import ServiceManagement
import Combine
import Foundation

@main
struct WatchControl_MacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var theListener = TheListener.shared
    @ObservedObject var menuState = LaunchOnStartupState.shared

    var body: some Scene {
        MenuBarExtra("WatchControl", image: "Image") {
            if !theListener.running {
                Button("Start") {
                    promptForAccessAndStart()
                }
            } else {
                Text(theListener.status)
            }
            Button("Logs") {
                let text = Log.shared.entries.map({$0.text}).joined(separator: "\n")
                let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
                let fileURL = tempDirectoryURL.appendingPathComponent("\(UUID().uuidString).txt")
                try? text.write(to: fileURL, atomically: true, encoding: .utf8)
                NSWorkspace.shared.open(fileURL)
            }
            Button("About") {
                let version = Util.getVersion()
                showAlert(title: "About WatchControl", message: "Created by Damian Mehers.\nVersion \(version)\nCopyright 2023 Atadore SARL.\nhttps://watchcontrol.app/")
            }.keyboardShortcut("a")
            Toggle(isOn: $menuState.launchOnLogin) {
                Text("Launch on startup")
            }
            .toggleStyle(.checkbox)
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
        }
    }
}

class LaunchOnStartupState : ObservableObject {
    static var shared = LaunchOnStartupState()
    @Published var launchOnLogin = SMAppService.mainApp.status == .enabled
    var cancelable: AnyCancellable?
    
    private init() {
        cancelable = $launchOnLogin.sink { newValue in
            do {
                if newValue {
                    Log.d("Calling SMAppService.mainApp.register()")
                    try SMAppService.mainApp.register()
                } else {
                    Log.d("Calling SMAppService.mainApp.unregister()")
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                Log.d("Error \(newValue ? "" : "un")registering for startup: \(error)")
            }
        }
    }
}


func promptForAccessAndStart() {
    if !TheListener.shared.hasAccessibilityAccess() {
        showAlert(title: "Accessibility Access Required", message: "In order to control the system audio, this app uses Accessibility.\n\nPlease go to System Settings|Privacy & Security|Accessibility and enable access for WatchControl.\n\nYou may need to add the app by pressing the '+' button at the bottom of the list.")
        TheListener.shared.up()
        
        Log.d("Has accessibility access: \(TheListener.shared.hasAccessibilityAccess())")
        
//        if !TheListener.shared.hasAccessibilityAccess() {
//            openAccessibilityPrivacyPreferences()
//        }
    }
}


func pollAccessibilityAccessStatus() {
    DispatchQueue.global(qos: .background).async {
        while true {
            Log.d("Checking for accessibility access")
            if TheListener.shared.hasAccessibilityAccess() {
                Log.d("App has accessibility access")
                TheListener.shared.start()
                break
            }
            sleep(1)
        }
        Log.d("Stopping polling")
    }
}

func openAccessibilityPrivacyPreferences() {
    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
        NSWorkspace.shared.open(url)
    }
}

func showAlert(title: String, message: String) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: "OK")
    alert.runModal()
}


class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Log.d("Has accessibility: \(TheListener.shared.hasAccessibilityAccess())")
        pollAccessibilityAccessStatus()
        promptForAccessAndStart()
    }
}

func activateApp() {
    let myApp = NSRunningApplication.current
    myApp.activate(options: .activateIgnoringOtherApps)
}
