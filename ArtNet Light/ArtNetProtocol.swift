//
//  ArtNetProtocol.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 30.04.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import Foundation

enum ArtNetPacketType: Int, Identifiable, CaseIterable {
    case address = 0
    case diagData
    case dmx
    case poll
    case pollReply
    
    var id: ArtNetPacketType {
        self
    }
    
    var literal: String {
        switch self {
        case .address: return "ArtAddress"
        case .diagData: return "ArtDiagData"
        case .dmx: return "ArtDmx"
        case .poll: return "ArtPoll"
        case .pollReply: return "ArtPollReply"
        }
    }
}

enum ArtNetOpCode: Int, Identifiable, CaseIterable {
    case poll = 0x2000
    case pollReply = 0x2100
    case diagData = 0x2300
    case dmx = 0x5000
    case address = 0x6000
    
    var id: ArtNetOpCode {
        self
    }
    
    var literal: String {
        switch self {
        case .poll: return "OpPoll"
        case .pollReply: return "OpPollReply"
        case .diagData: return "OpDiagData"
        case .dmx: return "OpDmx"
        case .address: return "OpAddress"
        }
    }
}

enum ArtAddressCommand: Int, Identifiable, CaseIterable {
    case none = 0
    case cancelMerge
    case ledNormal
    case ledMute
    case ledLocate
    case resetRxFlags
    case mergeLtp0 = 0x10
    case mergeLtp1
    case mergeLtp2
    case mergeLtp3
    case mergeHtp0 = 0x50
    case mergeHtp1
    case mergeHtp2
    case mergeHtp3
    case artNetSel0 = 0x60
    case artNetSel1
    case artNetSel2
    case artNetSel3
    case acnSel0 = 0x70
    case acnSel1
    case acnSel2
    case acnSel3
    case clearOp0 = 0x90
    case clearOp1
    case clearOp2
    case clearOp3
    
    var id: ArtAddressCommand {
        self
    }
    
    var literal: String {
        switch self {
        case .none: return "AcNone"
        case .cancelMerge: return "AcCancel Merge"
        case .ledNormal: return "AcLedNormal"
        case .ledMute: return "AcLedMute"
        case .ledLocate: return "AcLedLocate"
        case .resetRxFlags: return "AcResetRx Flags"
        case .mergeLtp0: return "AcMergeLtp0"
        case .mergeLtp1: return "AcMergeLtp1"
        case .mergeLtp2: return "AcMergeLtp2"
        case .mergeLtp3: return "AcMergeLtp3"
        case .mergeHtp0: return "AcMergeHtp0"
        case .mergeHtp1: return "AcMergeHtp1"
        case .mergeHtp2: return "AcMergeHtp2"
        case .mergeHtp3: return "AcMergeHtp3"
        case .artNetSel0: return "AcArtNetSel0"
        case .artNetSel1: return "AcArtNetSel1"
        case .artNetSel2: return "AcArtNetSel2"
        case .artNetSel3: return "AcArtNetSel3"
        case .acnSel0: return "AcAcnSel0"
        case .acnSel1: return "AcAcnSel1"
        case .acnSel2: return "AcAcnSel2"
        case .acnSel3: return "AcAcnSel3"
        case .clearOp0: return "AcClearOp0"
        case .clearOp1: return "AcClearOp1"
        case .clearOp2: return "AcClearOp2"
        case .clearOp3: return "AcClearOp3"
        }
    }
}

enum SwitchProgValues: Int, Identifiable, CaseIterable {
    case noChange = 0x7F
    case resetToPhysical = 0x00
    case zero = 0x80, one, two, three, four, five, six, seven, eight, nine, ten
    case eleven, twelve, thirteen, fourteen, fifthteen
    
    var id: SwitchProgValues {
        self
    }
    
    var literal: String {
        switch self {
        case .noChange: return "No Change"
        case .resetToPhysical: return "Reset to Physical"
        default: return "\(self.rawValue - 0x80)"
        }
    }
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
