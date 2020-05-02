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
    
    static func == (lhs: IpAddress, rhs: IpAddress) -> Bool {
        lhs.rawValues == rhs.rawValues
    }
    
    static func &(lhs: IpAddress, rhs: IpAddress) -> IpAddress {
        let values = zip(lhs.rawValues, rhs.rawValues).map{ $0.0 & $0.1 }
        
        return IpAddress(values[0], values[1], values[2], values[3])
    }
}
