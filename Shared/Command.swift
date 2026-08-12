//
//  File.swift
//  WatchControl
//
//  Created by Damian Mehers on 02.04.23.
//

import Foundation


struct Command: Codable {
    enum CommandKind : Int, Codable {
        case playPause
        case louder
        case quieter
        case previous
        case next
        case nop
        case muteUnmute
        case mouseMove
        case leftMouseClick
        case rightMouseClick
        case scroll
    }
    
    var id: String
    var sender: String
    var secret: String
    var kind: CommandKind
    var watchAppVersion: Double?
    var x: Double?
    var y: Double?
}
