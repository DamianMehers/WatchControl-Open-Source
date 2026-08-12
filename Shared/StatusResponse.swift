//
//  StatusResponse.swift
//  WatchControl
//
//  Created by Damian Mehers on 25.04.23.
//

import Foundation

struct StatusResponse: Codable {
    var volume: Double?
    var muted: Bool?
    var macAppVersion: Double?
}
