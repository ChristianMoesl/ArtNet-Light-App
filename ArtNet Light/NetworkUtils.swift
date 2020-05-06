//
//  NetworkUtils.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 02.05.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import Foundation

func computeDirectedBroadcastAddress(for address: IpAddress, with netmask: IpAddress) -> IpAddress {
    return address | ~netmask
}

func networkInterfaceInfo() -> (address: IpAddress, netmask: IpAddress)? {
    func stringToIpV4(_ s: String) -> IpAddress {
        let converted = s.split(separator: ".").map{ Int($0)! }
        return IpAddress(converted[0], converted[1], converted[2], converted[3])
    }
    
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
                let netmask = stringToIpV4(String(cString: buffer))
                
                getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                            &buffer, socklen_t(buffer.count),
                            nil, socklen_t(0), NI_NUMERICHOST)
                let address = stringToIpV4(String(cString: buffer))
                
                return (address: address, netmask: netmask)
            }
        }
    }

    freeifaddrs(ifaddr)

    return nil
}
