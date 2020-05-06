//
//  ArtNetNode.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 02.05.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import Foundation

struct ArtNetNodeInfo: Identifiable {
    let id = UUID()
    let ip: IpAddress
    let mac: [Int]
    let firmwareVersion: String
    let net: Int
    let subNet: Int
    let shortName: String
    let longName: String
    let nodeReport: String
    let dhcpOn: Bool
    let swIn: [Int]
    let swInEnabled: [Bool]
    let swOut: [Int]
    let swOutEnabled: [Bool]
}
