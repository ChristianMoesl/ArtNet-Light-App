//
//  ArtNetProtocol.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 17.04.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import Foundation
import Network
import NetworkExtension
import SwiftUI

class ArtNetMaster: ObservableObject {
    
    @Published var nodes = [ArtNetNodeInfo]()
    
    static let port = 6454
    static let id = [UInt8(ascii: "A"), UInt8(ascii: "r"), UInt8(ascii: "t"), UInt8(ascii: "-"), UInt8(ascii: "N"), UInt8(ascii: "e"), UInt8(ascii: "t"), UInt8(0)]
    static let protVerHi = UInt8(0)
    static let protVerLo = UInt8(14)
    static let protocolVersion =  [ArtNetMaster.protVerHi, ArtNetMaster.protVerLo]
    
    private var connection: NWConnection?
    private var pollConnection: NWConnection?
    
    private var inboundConnections = [NWConnection]()
    private var listener: NWListener?

    /*init() {
        let port = NWEndpoint.Port(rawValue: UInt16(ArtNetMaster.port))!
        
        do {
            self.listener = try NWListener(using: .udp, on: port)
            listener!.stateUpdateHandler = self.stateDidChange(to:)
            listener!.newConnectionHandler = self.didAccept(connection:)
            listener!.start(queue: .main)
        } catch {
            print("ERROR: Can not initialize Listener on UDP port: \(ArtNetMaster.port)")
        }
    }*/

    private func stateDidChange(to newState: NWListener.State) {
        switch newState {
        case .setup:
            break
        case .waiting:
            break
        case .ready:
            break
        case .failed(let error):
            print("Listener failed")
            print(error)
        case .cancelled:
            print("cancelled")
            break
        @unknown default:
            print("unhandled")
            break
        }
    }

    private func parseArtPollReply(_ data: Data) -> ArtNetNodeInfo? {
        let bytes = [UInt8](data)
        
        print("packet with length \(bytes.count) received")
        
        if bytes.count < 214 {
            return nil
        }
        
        let opCode = UInt16(bytes[9]) << 8 + UInt16(bytes[8])

        if bytes.prefix(8) == ArtNetMaster.id.prefix(8) &&
            opCode == UInt16(ArtNetOpCode.pollReply.rawValue) {
            print("parsed successfully")
            return ArtNetNodeInfo(
                ip: IpAddress(Int(bytes[10]), Int(bytes[11]), Int(bytes[12]), Int(bytes[13])),
                mac: [Int(bytes[201]), Int(bytes[202]), Int(bytes[203]), Int(bytes[204]), Int(bytes[205]), Int(bytes[206])],
                firmwareVersion: "\(bytes[16]).\(bytes[17])",
                net: Int(bytes[18]),
                subNet: Int(bytes[19]),
                shortName: String.init(bytes: bytes[26...43], encoding: .ascii) ?? "",
                longName: String.init(bytes: bytes[44...107], encoding: .ascii) ?? "",
                nodeReport: String.init(bytes: bytes[108...171], encoding: .ascii) ?? "",
                dhcpOn: bytes[212] & 0x02 > 0,
                swIn: bytes[186...189].map{ Int($0) },
                swInEnabled: bytes[174...177].map{ $0 & 0x40 > 0 },
                swOut: bytes[190...193].map{ Int($0) },
                swOutEnabled: bytes[174...177].map{ $0 & 0x80 > 0 }
            )
        }

        return nil
    }

    private func didAccept(connection: NWConnection) {
        inboundConnections.append(connection)
        
        connection.receiveMessage {
            (data, contentContext, isComplete, error) in
            print("received something")
            if let data = data, !data.isEmpty, isComplete {
                if let nodeInfo = self.parseArtPollReply(data) {
                    self.nodes.append(nodeInfo)
                }
            } else if let error = error {
                print("error: \(error)")
                // handle error
            }
            connection.cancel()
        }
    }

    private func stop() {
        if let listener = self.listener {
            self.listener = nil
            listener.cancel()
        }
        for connection in self.inboundConnections {
            connection.cancel()
        }
        self.inboundConnections.removeAll()
    }
    

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
        
        connection = prepare(connection: connection, to: ip.description)
        
        let channelValues = computeColorChannelValues(color: color, channelAssignment: channelAssignment)
        
        let data = (0...511).map { channelValues[$0 % channelValues.count] }
        
        let packet = prepareDmxHeader(net: net, subNet: subNet) + data

        send(content: packet)
    }
    
    func sendAddressPacket(to host: String, with params: ArtAddressParameters) {
        connection = prepare(connection: connection, to: host)
        
        let packet = prepareAddressPacket(with: params)
        
        send(content: packet)
    }
    
    func pollNodes() {
        nodes.removeAll()

        if let (ip, netmask) = networkInterfaceInfo() {
            let packet = preparePollPacket()
            
            let broadcastAddr = computeDirectedBroadcastAddress(for: ip, with: netmask)
            print("poll nodes from \(broadcastAddr)")
    
            pollConnection = prepare(connection: self.pollConnection, to: broadcastAddr.description)
            pollConnection!.send(content: packet, completion: .contentProcessed({ nwError in
                print("poll nodes sent")
                print(nwError?.debugDescription ?? "")
            }))
        }
    }
    
    private func send(content: Data) {
        connection!.send(content: content, completion: .contentProcessed({ nwError in
            if let error = nwError {
                print(error.debugDescription)
            }
        }))
    }

    private func preparePollPacket() -> Data {
        let talkToMe = UInt8(0x17)
        let dpLow = UInt8(0x10)
        let data = ArtNetMaster.id + [
            UInt8(ArtNetOpCode.poll.rawValue & 0xFF), UInt8(ArtNetOpCode.poll.rawValue >> 8)
        ] + ArtNetMaster.protocolVersion + [
            talkToMe,
            dpLow
        ]
        
        return Data(data)
    }
    
    private func prepare(connection: NWConnection?, to host: String) -> NWConnection {
        let endpoint = NWEndpoint.Host(host)
        if (connection?.endpoint.debugDescription ?? "") != "\(host):\(ArtNetMaster.port)" {
            let con = NWConnection(host: endpoint,
                                   port: NWEndpoint.Port("\(ArtNetMaster.port)")!,
                                   using: .udp)
            con.start(queue: .global())
            return con
        }
        
        return connection!
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
            UInt8(opCode & 0xFF), UInt8(opCode >> 8)
        ] + ArtNetMaster.protocolVersion + [
            sequence,
            physical,
            UInt8(subNet),
            UInt8(net),
            UInt8(dataLength >> 8), UInt8(dataLength & 0xFF)
        ])
    }
}
