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

class LightStore: ObservableObject {
    //var managedObjectContext: NSManagedObjectContext
    private var lights: FetchedResults<LightEntity>
    
    init(/*managedObjectContext: NSManagedObjectContext,*/ lights: FetchedResults<LightEntity>) {
        //self.managedObjectContext = managedObjectContext
        self.lights = lights
    }
    
    func getAll() -> FetchedResults<LightEntity> {
        lights
    }
    
    var count: Int {
        lights.count
    }
}

class LightViewModel: ObservableObject {
    
    // Input
    @Published var color: UIColor
    @Published var selected = 0

    // Output
    var name: String {
        lightsCount > 0 ? currentLight.name_ : ""
    }
    var canSelectNext: Bool {
        selected < store.count - 1
    }
    var canSelectPrevious: Bool {
        selected > 0
    }
    
    var lightsCount: Int {
        store.count
    }
    private var artNet = ArtNetMaster()
    
    private var cancellableSet: Set<AnyCancellable> = []
    
    private var store: LightStore
    private var lights: FetchedResults<LightEntity>
    
    private var currentLight: LightEntity {
        lights[selected]
    }
    
    private func updateColor(color: UIColor) {
        currentLight.color = color
        
        let ip = (Int(currentLight.ipAddress0),
                  Int(currentLight.ipAddress1),
                  Int(currentLight.ipAddress2),
                  Int(currentLight.ipAddress3))

        let channelAssignment = currentLight.channelNumber == 3
            ? currentLight.channelAssignmentFor3
            : currentLight.channelAssignmentFor4

        artNet.sendDmxDirectedBroadcast(ip: ip, net: Int(currentLight.net), subNet: Int(currentLight.subnet), color: color, channelAssignment: channelAssignment)
    }
    
    init(store: LightStore) {
        self.store = store
        self.lights = store.getAll()
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
            .navigationBarItems(trailing: NavigationLink(destination: LightSettingsView()) {
                Image(systemName: "gear")
                    .resizable()
                    .frame(width: 32, height: 32, alignment: .center)
            })
        }
    }
}


struct ContentView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(entity: LightEntity.entity(), sortDescriptors: []) var lights: FetchedResults<LightEntity>
    
    var body: some View {
        DimmerView(lightViewModel: LightViewModel(store: LightStore(/*managedObjectContext: managedObjectContext, */lights: lights)))
    }
}

struct ContentView_Previews: PreviewProvider {
   /* static let testData = [
        Light(name: "Spots", address: [192,168,1,255], net: 0, subnet: 0, port: 0),
        Light(name: "Led Streifen", address: [192,168,1,255], net: 0, subnet: 0, port: 1)
    ]*/

    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let light = LightEntity(context: context)
        light.id = UUID()
        light.name = "Led Spots"
        light.ipAddress0 = 192
        light.ipAddress1 = 168
        light.ipAddress2 = 1
        light.ipAddress3 = 255
        light.net = 1
        light.subnet = 0

        return ContentView().environment(\.managedObjectContext, context)
    }
}
