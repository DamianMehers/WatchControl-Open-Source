//
//  MacInfo.swift
//  WatchControl
//
//  Created by Damian Mehers on 02.04.23.
//

import Foundation

struct MacInfo : Codable {
    var serviceId: String
    var name: String
    var lastUpdate: Date
    var secret: String
    var version: String
}
