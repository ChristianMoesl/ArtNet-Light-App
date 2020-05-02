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

class LightViewModel: ObservableObject {
    
    // Input
    @Published var color: UIColor
    @Published var selected = 0

    // Output
    var name: String {
        lightsCount > 0 ? currentLight.name : ""
    }
    var canSelectNext: Bool {
        selected < lights.count - 1
    }
    var canSelectPrevious: Bool {
        selected > 0
    }
    
    var lightsCount: Int {
        lights.count
    }
    private let artNet: ArtNetMaster
    
    private var cancellableSet: Set<AnyCancellable> = []
    
    private var lights: FetchedResults<Light>
    
    private var currentLight: Light {
        lights[selected]
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

    init(artNet: ArtNetMaster, lights: FetchedResults<Light>) {
        self.artNet = artNet
        self.lights = lights
        self.color = UIColor.white
        
        if lights.count > 0 && currentLight.color != color {
            color = currentLight.color
        }

        $color
            .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .sink{ color in
                if self.lights.count > 0 && self.currentLight.color != color {
                    self.updateColor(color: color)
                }
            }.store(in: &cancellableSet)
    }
    
    func selectNext() {
        selected += 1
    }
    
    func selectPrevious() {
        selected -= 1
    }
}

struct DimmerView: View {
    @ObservedObject var lightViewModel: LightViewModel

    var body: some View {
        NavigationView {
            VStack {
                if lightViewModel.lightsCount > 0 {
                    VStack {
                        ColorPicker(color: $lightViewModel.color)
                            .alignmentGuide(HorizontalAlignment.center, computeValue: { _ in 150 })
                    }.frame(alignment: .center)

    
                    HStack {
                        Button(action: { self.lightViewModel.selectPrevious() }, label: {
                            Image(systemName: "arrow.left.circle")
                                .resizable()
                                .frame(width: 64, height: 64, alignment: .center)
                        }).disabled(!self.lightViewModel.canSelectPrevious)
                        Text(lightViewModel.name)
                        Button(action: { self.lightViewModel.selectNext() }, label: {
                            Image(systemName: "arrow.right.circle")
                                .resizable()
                                .frame(width: 64, height: 64, alignment: .center)
                        })
                        .disabled(!self.lightViewModel.canSelectNext)
                    }
                } else {
                    Text("Please configure a light")
                }
            }
            .navigationBarTitle(Text("Dimmer"), displayMode: .inline)
            .navigationBarItems(trailing: NavigationLink(destination: SettingsView()) {
                Image(systemName: "gear")
                    .resizable()
                    .frame(width: 32, height: 32, alignment: .center)
            })
        }
    }
}


struct ContentView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var artNet: ArtNetMaster
    @FetchRequest(entity: Light.entity(), sortDescriptors: []) var lights: FetchedResults<Light>
    
    var body: some View {
        DimmerView(lightViewModel: LightViewModel(artNet: artNet, lights: lights))
    }
}

struct ContentView_Previews: PreviewProvider {
   /* static let testData = [
        Light(name: "Spots", address: [192,168,1,255], net: 0, subnet: 0, port: 0),
        Light(name: "Led Streifen", address: [192,168,1,255], net: 0, subnet: 0, port: 1)
    ]*/

    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let light = Light(context: context)
        light.id = UUID()
        light.name = "Led Spots"
        light.ipAddress = IpAddress(192, 168, 1, 255)

        return ContentView().environment(\.managedObjectContext, context)
    }
}
