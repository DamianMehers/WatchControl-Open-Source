//
//  Log.swift
//  WatchControl
//
//  Created by Damian Mehers on 02.04.23.
//

import Foundation

#if os(watchOS)
import WatchKit
#endif


class Log: ObservableObject {
    let logURL = URL(string: "TBS")!
    let apiKey = "TBS"
    let maxUpload = 128 * 1024
    
    struct Entry: Identifiable {
        let id = UUID()
        let text: String
    }
    
    static let shared = Log()
    let dateFormatter = DateFormatter()
    
    @Published var message = "";
    @Published var haveMessage = false
    @Published var working = false
    
    private init() {
        dateFormatter.dateFormat = "HH:mm"
    }
    
    @Published
    @MainActor
    var entries = [Entry]()
    
    @MainActor
    func submit(feedback:String ) async {
        // TBS your code here
    }
    
    
    // From https://stackoverflow.com/a/30075200/3390
    private var modelIdentifier: String {
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulatorModelIdentifier }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }
    
    var osVersion: String {
        #if os(iOS)
        return UIDevice.current.systemVersion
        #elseif os(macOS)
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        return "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        #elseif os(watchOS)
        return WKInterfaceDevice.current().systemVersion
        #else
        fatalError("Unrecognized OS")
        #endif
        
    }
    
    var watchModel: String {
        var size: size_t = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = CChar()
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        
        return String(machine)
        
//        return String(cString: &machine, encoding: String.Encoding.utf8)?.trimmingCharacters(in: .whitespaces) ?? "unknown"
    }
    
    var build: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        
        return "\(version ?? "?") (\(build ?? "?"))"
    }
    
    
    private func add(_ entry: String) {
        let entryWithTimestamp = "\(dateFormatter.string(from: Date())) \(entry)"
        print(entryWithTimestamp)
        let entry = Entry(text: entryWithTimestamp)
        DispatchQueue.main.async {
            self.entries.insert(entry, at: 0)
        }
    }
    
    static func d(_ entry: String) {
        shared.add(entry)
    }
}
