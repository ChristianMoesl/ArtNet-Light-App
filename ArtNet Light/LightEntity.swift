//
//  Light.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 17.04.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import Foundation
import SwiftUI

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

extension LightEntity {
    
    var name_: String {
        get { name ?? "" }
        set { name = newValue }
    }
    
    var color: UIColor {
        set {
            let (r,g,b,a) = newValue.rgba

            red = Double(r)
            green = Double(g)
            blue = Double(b)
            alpha = Double(a)
        }
        get {
           return UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
        }
    }
    
    var channelAssignmentFor3: [ColorChannel] {
        set {
            let new = newValue + [.white]
            channelAssignmentFor4 = new
        }
        get {
            channelAssignmentFor4.filter{ $0 != .white }
        }
    }

    var channelAssignmentFor4: [ColorChannel] {
        set {
            for (idx, color) in newValue.enumerated() {
                let i = Int16(idx)
                switch color {
                case .red:
                    if channelRed != i { channelRed = i }
                case .green:
                    if channelGreen != i { channelGreen = i }
                case .blue:
                    if channelBlue != i { channelBlue = i }
                case .white:
                    if channelWhite != i { channelWhite = i }
                }
            }
        }
        get {
            [
                (ColorChannel.red, Int(channelRed)),
                (ColorChannel.green, Int(channelGreen)),
                (ColorChannel.blue, Int(channelBlue)),
                (ColorChannel.white, Int(channelWhite))
                ].sorted{ $0.1 < $1.1 }
            .map{ $0.0 }
        }
    }
}
