//
//  UniverseDetailView.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 04.05.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class UniverseDetailViewModel: ObservableObject, Identifiable {
    
    var net: Int {
        set { universe.net = newValue }
        get { universe.net }
    }
    var subnet: Int {
        set { universe.subnet = newValue }
        get { universe.subnet }
    }
    var numberOfLightPoints: Int {
        set { universe.numberOfLightPoints = newValue }
        get { universe.numberOfLightPoints }
    }
    
    let id: UUID
    
    private let universe: Universe
    private var cancellableSet: Set<AnyCancellable> = []
    
    init(for universe: Universe, in lightStore: LightStore) {
        self.universe = universe
        self.id = universe.id
        
        universe.objectWillChange
            .sink(receiveValue: { [weak self] in
                self?.objectWillChange.send()
            })
            .store(in: &cancellableSet)
    }
}


struct UniverseDetailView: View {
    @ObservedObject var viewModel: UniverseDetailViewModel
    
    private let netOptions = [Int](0...127)
    private let subnetOptions = [Int](0...255)

    var body: some View {
        Form {
            Picker("Net", selection: $viewModel.net) {
                ForEach(netOptions, id: \.self) { option in
                    Text("\(option)")
                }
            }
            Picker("Sub-Net", selection: $viewModel.subnet) {
                ForEach(subnetOptions, id: \.self) { option in
                    Text("\(option)")
                }
            }
            NumberField("Light Points", value: $viewModel.numberOfLightPoints)
        }
    }
}

