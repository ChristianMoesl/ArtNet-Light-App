//
//  MicrophoneMonitor.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 07.05.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import Foundation
import SwiftUI
import AVFoundation
import Accelerate

class MicrophoneMonitor: ObservableObject {
    let engine = AVAudioEngine()
    
    @Published var decibels: Double = 0

    init() {
        print("MicrophoneMonitor::init()")
        
        let node = engine.inputNode
        let format = node.inputFormat(forBus: 0)
        let recordingFormat = node.outputFormat(forBus: 0)
        let reference = Double(5.0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, time in
            let values = Array(
                UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength))
            )
            
            let rms = Double(vDSP.rootMeanSquare(values))
            let decibels = 20 * log10(rms / reference) + 120.0
            DispatchQueue.main.async {
                self.decibels = decibels
            }
        }
        engine.prepare()
        try! engine.start()
    }
}
