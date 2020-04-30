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

class ArtNetMaster: ObservableObject {
    static let port = 6454
    static let id = [UInt8(ascii: "A"), UInt8(ascii: "r"), UInt8(ascii: "t"), UInt8(ascii: "-"), UInt8(ascii: "N"), UInt8(ascii: "e"), UInt8(ascii: "t"), UInt8(0)]
    static let protVerHi = UInt8(0)
    static let protVerLo = UInt8(14)
    
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
    
    struct ArtAddressParameters {
        var net: Int
        var subNet: Int
        var bindIndex: Int
        var shortName: String
        var longName: String
        var swIn: [SwitchProgValues]
        var swOut: [SwitchProgValues]
        var command: ArtAddressCommand
    }
    
    func sendAddressPacket(to host: String, with params: ArtAddressParameters) {
        connection = prepareConnection(to: host)
        
        let packet = prepareAddressPacket(with: params)
        
        connection!.send(content: packet, completion: NWConnection.SendCompletion.contentProcessed(({ nwError in
            print(nwError?.debugDescription)
        })))
    }
    
    private func prepareConnection(to host: String) -> NWConnection {
        let endpoint = NWEndpoint.Host(host)
        if (connection?.endpoint.debugDescription ?? "") != "\(host):\(ArtNetMaster.port)" {
            let con = NWConnection(host: endpoint,
                                   port: NWEndpoint.Port("\(ArtNetMaster.port)")!,
                                   using: .udp)
            con.start(queue: .global())
            return con
        }
        
        return self.connection!
    }
   
    private func prepareConnection(to ip: (Int, Int, Int, Int)) -> NWConnection {
        let host = "\(ip.0).\(ip.1).\(ip.2).\(ip.3)"
        return prepareConnection(to: host)
    }
    
    private func prepareAddressPacket(with params: ArtAddressParameters) -> Data {
        let opCode = UInt16(ArtNetOpCode.address.rawValue)
        
        let firstPart = ArtNetMaster.id + [
            UInt8(opCode & 0xFF), UInt8(opCode >> 8),
            ArtNetMaster.protVerHi,
            ArtNetMaster.protVerLo,
            UInt8(params.net),
            UInt8(params.bindIndex)
        ]
        
        let short = Array(params.shortName.prefix(17).utf8)
        let long = Array(params.longName.prefix(63).utf8)
        let serializedNames = short + [UInt8](repeating: 0, count: 18 - short.count) +
            long + [UInt8](repeating: 0, count: 64 - long.count)
        let swInSer = params.swIn.map{ UInt8($0.rawValue) }
        let swOutSer = params.swOut.map{ UInt8($0.rawValue) }
        
        let lastPart = [
            UInt8(params.subNet),
            UInt8(0),
            UInt8(params.command.rawValue)
        ]

        return Data(firstPart + serializedNames + swInSer + swOutSer + lastPart)
    }
   
    private func prepareDmxHeader(net: Int, subNet: Int) -> Data {
        let opCode = UInt16(ArtNetOpCode.dmx.rawValue)
        let sequence = UInt8(0) // disable resequencing
        let physical = UInt8(0)
        let dataLength = UInt16(512)

        return Data(ArtNetMaster.id + [
            UInt8(opCode & 0xFF), UInt8(opCode >> 8),
            ArtNetMaster.protVerHi, ArtNetMaster.protVerLo,
            sequence,
            physical,
            UInt8(subNet),
            UInt8(net),
            UInt8(dataLength >> 8), UInt8(dataLength & 0xFF)
        ])
    }
    

    
}
