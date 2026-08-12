//
//  Util.swift
//  WatchControl
//
//  Created by Damian Mehers on 02.04.23.
//

import Foundation

struct Util {
    static func getVersion() -> String {
        if let info = Bundle.main.infoDictionary {
                    let version = info["CFBundleShortVersionString"] as? String ?? "Unknown"
                    let build = info["CFBundleVersion"] as? String ?? "Unknown"
                    return "\(version), \(build)"
                }
        return "unknown"
        
    }

}
