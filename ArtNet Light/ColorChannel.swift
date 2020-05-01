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

