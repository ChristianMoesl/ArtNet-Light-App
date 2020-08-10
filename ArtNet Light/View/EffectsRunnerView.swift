//
//  EffectsRunnerView.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 07.05.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import SwiftUI
import MediaPlayer
import Combine

class EffectsRunnerViewModel: ObservableObject {
    let microphoneMonitor = MicrophoneMonitor()

    var decibels: Double {
        microphoneMonitor.decibels
    }
    
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        microphoneMonitor.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }
        .store(in: &cancellables)
    }
}

struct EffectsRunnerView: View {
    @ObservedObject var viewModel: EffectsRunnerViewModel
    
    var body: some View {
        AudioMeter(decibels: viewModel.decibels)
    }
}

struct EffectsRunnerView_Previews: PreviewProvider {
    static var previews: some View {
        EffectsRunnerView(viewModel: EffectsRunnerViewModel())
    }
}
