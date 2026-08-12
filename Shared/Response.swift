//
//  Response.swift
//  WatchControl
//
//  Created by Damian Mehers on 02.04.23.
//

import Foundation

struct Response: Codable {
    let version: String
    let id: String
    let message: String?
    let sender: String
}
