//
//  ArtNetProtocol.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 17.04.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import Foundation
import Network
import SwiftUI

class ArtNetMaster {
    static let port = 6454
    
    typealias IpAddress = (Int, Int, Int, Int)

    private var connection: NWConnection?
    
    private func tryComputeWhite(for color: UIColor) -> UInt8? {
        let (hue, saturation, brightness, _) = color.hsva
        return hue == 0 && saturation == 0 ? UInt8(brightness * 255) : nil
    }
    
    private func computeColorChannelValues(color: UIColor, channelAssignment: [ColorChannel]) -> [UInt8] {
        let (r,g,b,_) = color.rgba
        var values = [
            (UInt8(r * 255), channelAssignment.firstIndex(of: .red)!),
            (UInt8(g * 255), channelAssignment.firstIndex(of: .green)!),
            (UInt8(b * 255), channelAssignment.firstIndex(of: .blue)!)
        ]
        
        if channelAssignment.count == 4 {
            if let whiteValue = tryComputeWhite(for: color) {
                values = values.map{ (UInt8(0), $0.1) } + [
                    (whiteValue, channelAssignment.firstIndex(of: .white)!)
                ]
            } else {
                values += [(UInt8(0), channelAssignment.firstIndex(of: .white)!)]
            }
        }
        
        return values.sorted{ $0.1 > $1.1 }.map{ $0.0 }
    }

    func sendDmxDirectedBroadcast(ip: IpAddress, net: Int, subNet: Int, color: UIColor, channelAssignment: [ColorChannel]) {
        precondition((3...4).contains(channelAssignment.count), "RGB and RGBW supported only")
        
        connection = prepareConnection(to: ip)
        
        let channelValues = computeColorChannelValues(color: color, channelAssignment: channelAssignment)
        
        let data = (0...511).map { channelValues[$0 % channelValues.count] }
        
        let packet = prepareDmxHeader(net: net, subNet: subNet) + data

        connection!.send(content: packet, completion: NWConnection.SendCompletion.contentProcessed(({ nwError in
            print(nwError?.debugDescription)
        })))
    }
   
    private func prepareConnection(to ip: (Int, Int, Int, Int)) -> NWConnection {
        let host = NWEndpoint.Host("\(ip.0).\(ip.1).\(ip.2).\(ip.3)")
       
        if (connection?.endpoint.debugDescription ?? "") != "\(host):\(ArtNetMaster.port)" {
            let con = NWConnection(host: host,
                               port: NWEndpoint.Port("\(ArtNetMaster.port)")!,
                               using: .udp)
            con.start(queue: .global())
            return con
        }
        
        return self.connection!
    }
   
    private func prepareDmxHeader(net: Int, subNet: Int) -> Data {
        let id = [UInt8(ascii: "A"), UInt8(ascii: "r"), UInt8(ascii: "t"), UInt8(ascii: "-"), UInt8(ascii: "N"), UInt8(ascii: "e"), UInt8(ascii: "t"), UInt8(0)]
        let opCode = UInt16(0x5000)
        let protVerHi = UInt8(0)
        let protVerLo = UInt8(14)
        let sequence = UInt8(0) // disable resequencing
        let physical = UInt8(0)
        let dataLength = UInt16(512)

        return Data(id + [
            UInt8(opCode & 0xFF), UInt8(opCode >> 8),
            protVerHi, protVerLo,
            sequence,
            physical,
            UInt8(subNet),
            UInt8(net),
            UInt8(dataLength >> 8), UInt8(dataLength & 0xFF)
        ])
    }
}
