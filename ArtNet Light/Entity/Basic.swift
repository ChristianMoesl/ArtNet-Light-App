//
//  Basic.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 02.05.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import Foundation


class IpAddress: CustomStringConvertible, Equatable {
    private(set) var rawValues: [Int]
    
    init(_ val1: Int, _ val2: Int, _ val3: Int, _ val4: Int) {
        rawValues = [val1, val2, val3, val4]
    }
    
    var description: String {
        rawValues.map{ String($0) }.joined(separator: ".")
    }
    
    private static func elementWise(_ lhs: IpAddress, _ rhs: IpAddress, modifier: (Int, Int) -> Int) -> IpAddress {
        let values = zip(lhs.rawValues, rhs.rawValues).map(modifier)
        
        return IpAddress(values[0], values[1], values[2], values[3])
    }
    
    private static func elementWise(_ lhs: IpAddress, modifier: (Int) -> Int) -> IpAddress {
        let values = lhs.rawValues.map(modifier)
        
        return IpAddress(values[0], values[1], values[2], values[3])
    }
    
    static func == (lhs: IpAddress, rhs: IpAddress) -> Bool {
        lhs.rawValues == rhs.rawValues
    }
    
    static func & (lhs: IpAddress, rhs: IpAddress) -> IpAddress {
        elementWise(lhs, rhs) { $0 & $1 }
    }
    
    static func | (lhs: IpAddress, rhs: IpAddress) -> IpAddress {
        elementWise(lhs, rhs) { $0 | $1 }
    }
    
    static prefix func ~ (element: IpAddress) -> IpAddress {
        elementWise(element) { Int(~UInt8($0)) }
    }
}

enum ColorChannel: Int, CaseIterable, Identifiable {
    case red = 0
    case green
    case blue
    case white
    
    var id: ColorChannel {
        self
    }

    var literal: String {
        switch self {
        case .red: return "Red"
        case .green: return "Green"
        case .blue: return "Blue"
        case .white: return "White"
        }
    }
}

