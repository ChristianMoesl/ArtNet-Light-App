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

struct ArtNodeInfo: Identifiable {
    let id = UUID()
    let ip: (Int, Int, Int, Int)
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

class ArtNetMaster: ObservableObject {
    
    @Published var nodes = [ArtNodeInfo]()
    
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
        }
    }

    private func parseArtPollReply(_ data: Data) -> ArtNodeInfo? {
        let bytes = [UInt8](data)
        
        print("packet with length \(bytes.count) received")
        
        if bytes.count < 214 {
            return nil
        }
        
        let opCode = UInt16(bytes[9]) << 8 + UInt16(bytes[8])

        if bytes.prefix(8) == ArtNetMaster.id.prefix(8) &&
            opCode == UInt16(ArtNetOpCode.pollReply.rawValue) {
            print("parsed successfully")
            return ArtNodeInfo(
                ip: (Int(bytes[10]), Int(bytes[11]), Int(bytes[12]), Int(bytes[13])),
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

        connection!.send(content: packet, completion: .contentProcessed(({ nwError in
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
        connection = prepare(connection: connection, to: host)
        
        let packet = prepareAddressPacket(with: params)
        
        connection!.send(content: packet, completion: .contentProcessed({ nwError in
            print(nwError?.debugDescription)
        }))
    }
    
    func pollNodes() {
        nodes.removeAll()

        if let (ip, netmask) = networkInterfaceInfo() {
            let packet = preparePollPacket()
            
            let broadcastAddr = computeDirectedBroadcastAddress(for: ip, with: netmask)
            print("poll nodes from \(broadcastAddr)")
    
            pollConnection = prepare(connection: self.pollConnection, to: broadcastAddr)
            pollConnection!.send(content: packet, completion: .contentProcessed({ nwError in
                print("poll nodes sent")
                print(nwError?.debugDescription ?? "")
            }))
        }
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
    
    private func computeDirectedBroadcastAddress(for address: String, with netmask: String) -> String {
        func addressToInt(_ addr: String) -> UInt32 {
            addr.split(separator: ".").map{ UInt32(Int($0)!) }.reduce(0){ $0 << 8 + $1 }
        }
        
        let ip = addressToInt(address)
        let mask = addressToInt(netmask)

        var directedBroadcast = ip | ~mask
        
        var bytes = [Int](repeating: 0, count: 4)
        
        for i in (0...3).reversed() {
            bytes[i] = Int(directedBroadcast & 0xFF)
            directedBroadcast = directedBroadcast >> 8
        }
        
        return bytes.map{ String($0) }.joined(separator: ".")
    }
    
    private func networkInterfaceInfo() -> (address: String, netmask: String)? {
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }

        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee

            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) /*|| addrFamily == UInt8(AF_INET6)*/ {

                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if  name == "en0" {

                    // Convert interface address to a human readable string:
                    var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    
                    getnameinfo(interface.ifa_netmask, socklen_t(interface.ifa_netmask.pointee.sa_len),
                                &buffer, socklen_t(buffer.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    let netmask = String(cString: buffer)
                    
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &buffer, socklen_t(buffer.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    let address = String(cString: buffer)
                    
                    return (address: address, netmask: netmask)
                }
            }
        }

        freeifaddrs(ifaddr)

        return nil
    }
}
