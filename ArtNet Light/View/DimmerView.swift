//  ContentView.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 12.04.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import SwiftUI
import CoreData
import Combine
import SwiftHSVColorPicker

class DimmerViewModel: ObservableObject {
    
    // Input
    @Published var color: UIColor

    // Output
    @Published private(set) var selected = 0
    
    var name: String {
        lightsCount > 0 ? currentLight.name : ""
    }
    var canSelectNext: Bool {
        selected < lightStore.lights.count - 1
    }
    var canSelectPrevious: Bool {
        selected > 0
    }
    
    var lightsCount: Int {
        lightStore.lights.count
    }
    
    let settingsViewModel: SettingsViewModel
    
    private let artNet: ArtNetMaster
    private let lightStore: LightStore
    
    private var cancellableSet: Set<AnyCancellable> = []

    private var currentLight: Light {
        lightStore.lights[selected]
    }

    init(artNet: ArtNetMaster, lightStore: LightStore) {
        self.artNet = artNet
        self.lightStore = lightStore
        self.color = UIColor.white
        self.settingsViewModel = .init(lightStore)
        
        updateColor()

        $color
            .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .sink{ [weak self] color in
                if self != nil && self!.lightStore.lights.count > 0 && self!.currentLight.color != color {
                    self!.updateColor(color: color)
                }
            }.store(in: &cancellableSet)
    }
    
    func selectNext() {
        selected += 1
        
        updateColor()
    }
    
    func selectPrevious() {
        selected -= 1
        
        updateColor()
    }
    
    private func updateColor(color: UIColor) {
        currentLight.color = color
        
        let channelAssignment = currentLight.channelNumber == 3
            ? currentLight.channelAssignmentFor3
            : currentLight.channelAssignmentFor4
        
        for universe in currentLight.universes {
            artNet.sendDmxDirectedBroadcast(ip: currentLight.ipAddress, net: universe.net, subNet: universe.subnet, color: color, channelAssignment: channelAssignment)
        }
    }
    
    private func updateColor() {
        if lightStore.lights.count > 0 && currentLight.color != color {
            color = currentLight.color
        }
    }
}

struct DimmerView: View {
    @ObservedObject var viewModel: DimmerViewModel
    
    var effectsRunnerLink: some View {
        Text("")
    }
    
    var settingsLink: some View {
        NavigationLink(destination: SettingsView(viewModel: viewModel.settingsViewModel)) {
            Image(systemName: "gear")
                .resizable()
                .frame(width: 32, height: 32, alignment: .center)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.lightsCount > 0 {
                    VStack {
                        GeometryReader { proxy in
                            ColorPicker(frame: proxy.frame(in: .local), color: self.$viewModel.color)
                        }
                        HStack {
                            Button(action: { self.viewModel.selectPrevious() }, label: {
                                Image(systemName: "arrow.left.circle")
                                    .resizable()
                                    .frame(width: 64, height: 64, alignment: .center)
                            }).disabled(!self.viewModel.canSelectPrevious)
                            Text(self.viewModel.name)
                                .frame(width: 128, height: nil, alignment: .center)
                                .font(Font.headline.weight(.semibold))
                            Button(action: { self.viewModel.selectNext() }, label: {
                                Image(systemName: "arrow.right.circle")
                                    .resizable()
                                    .frame(width: 64, height: 64, alignment: .center)
                            })
                            .disabled(!self.viewModel.canSelectNext)
                        }
                        .padding(48)
                    }.frame(alignment: .center)
                } else {
                    Text("Please configure a light")
                }
            }
            .navigationBarTitle(Text("Dimmer"), displayMode: .inline)
            .navigationBarItems(leading: effectsRunnerLink, trailing: settingsLink)
        }
    }
}

struct ContentView_Previews: PreviewProvider {

    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let light = Light(context: context)
        light.name = "Led Spots"
        light.ipAddress = IpAddress(192, 168, 1, 255)
        
        let store = LightStore()
        store.fetchLights()
        let viewModel = DimmerViewModel(artNet: ArtNetMaster(), lightStore: store)
        
        return DimmerView(viewModel: viewModel).environment(\.managedObjectContext, context)
    }
}
