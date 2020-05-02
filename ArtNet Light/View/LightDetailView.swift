//
//  LightDetail.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 12.04.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import SwiftUI
import Combine



class LightDetailViewModel: ObservableObject {
    var light: Light

    // Input
    @Published var ipAddressField: String
    @Published var channelAssignmentFor3: [ColorChannel]
    @Published var channelAssignmentFor4: [ColorChannel]
    
    // Output
    @Published private(set) var ipAddressValid = true
    
    private var cancellableSet: Set<AnyCancellable> = []
    
    private func saveIPAddress(address: IpAddress) {
        if light.ipAddress != address {
            light.ipAddress = address
        }
    }
    
    private func parseIPAddress(text: String) -> IpAddress? {
        let number = "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
        let regex = "^\(number).\(number).\(number).\(number)$"
        let matches = text.groups(for: regex)
        
        return matches.count == 0 ?
            nil : IpAddress(Int(matches[0][1])!, Int(matches[0][2])!, Int(matches[0][3])!, Int(matches[0][4])!)
    }
    
    private var ipAddressValidator: AnyPublisher<IpAddress?, Never> {
        $ipAddressField
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .removeDuplicates()
            .map(parseIPAddress)
            .eraseToAnyPublisher()
    }
    
    private func saveChannelAssignments(assignments: [ColorChannel]) {
        if assignments.count == 4 && light.channelAssignmentFor4 != assignments {
            light.channelAssignmentFor4 = assignments
        } else if assignments.count == 3 && light.channelAssignmentFor3 != assignments {
            light.channelAssignmentFor3 = assignments
        }
    }
    

    init(light: Light) {
        self.light = light
        self.ipAddressField = light.ipAddress.description
        self.channelAssignmentFor3 = light.channelAssignmentFor3
        self.channelAssignmentFor4 = light.channelAssignmentFor4

        ipAddressValidator
            .receive(on: RunLoop.main)
            .map{ $0 != nil }
            .assign(to: \.ipAddressValid, on: self)
            .store(in: &cancellableSet)
        
        ipAddressValidator
            .sink{ result in
                if let address = result {
                    self.saveIPAddress(address: address)
                }
            }
            .store(in: &cancellableSet)
        
        $channelAssignmentFor3.merge(with: $channelAssignmentFor4)
            .receive(on: RunLoop.main)
            .sink{ assignments in self.saveChannelAssignments(assignments: assignments) }
            .store(in: &cancellableSet)
    }
}

// Takes any collection of T and returns an array of permutations
func permute<C: Collection>(items: C) -> [[C.Iterator.Element]] {
    var scratch = Array(items) // This is a scratch space for Heap's algorithm
    var result: [[C.Iterator.Element]] = [] // This will accumulate our result

    // Heap's algorithm
    func heap(_ n: Int) {
        if n == 1 {
            result.append(scratch)
            return
        }

        for i in 0..<n-1 {
            heap(n-1)
            let j = (n%2 == 1) ? 0 : i
            scratch.swapAt(j, n-1)
        }
        heap(n-1)
    }

    // Let's get started
    heap(scratch.count)

    // And return the result we built up
    return result
}

struct LightDetailView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @ObservedObject var light: Light
    
    @ObservedObject var viewModel: LightDetailViewModel

    init(light: Light) {
        self.light = light
        self.viewModel = LightDetailViewModel(light: light)
    }
    
    private let channels3Options = permute(items: ColorChannel.allCases.filter{ $0 != .white })
    private let channels4Options = permute(items: ColorChannel.allCases)

    var body: some View {
        Form {
            Section(header: Text(LocalizedStringKey("Name"))) {
                TextField(LocalizedStringKey("Name"), text: $light.name)
            }
            Section(header: Text(LocalizedStringKey("Network"))) {
                TextField("IP Address", text: $viewModel.ipAddressField)
                    .keyboardType(.numbersAndPunctuation)
                if !viewModel.ipAddressValid {
                    Text("IP address has wrong format")
                        .fontWeight(.light)
                        .font(.footnote)
                        .foregroundColor(Color.red)
                }
            }
            Section(header: Text("Light")) {
                Stepper(value: $light.channelNumber, in: 3...4, label: {
                    Text("Number of Channels: \(light.channelNumber)")
                })
                if light.channelNumber == 3 {
                    Picker("Channel Assignment", selection: $viewModel.channelAssignmentFor3) {
                        ForEach(channels3Options, id: \.self) { option in
                            Text(option.map{ "\($0)" }.joined(separator: " / ")).tag(option)
                        }
                    }
                } else {
                    Picker("Channel Assignment", selection: $viewModel.channelAssignmentFor4) {
                        ForEach(channels4Options, id: \.self) { option in
                            Text(option.map{ "\($0)" }.joined(separator: " / ")).tag(option)
                        }
                    }
                }
                NavigationLink("Lightpoints", destination: UniverseListView(light: light))
            }
            /*Section(header: Text("ArtNet")) {
                Picker("Net", selection: $light.net) {
                    ForEach(netOptions, id: \.self) { option in
                        Text("\(option)")
                    }
                }
                Picker("Sub-Net", selection: $light.subnet) {
                    ForEach(subnetOptions, id: \.self) { option in
                        Text("\(option)")
                    }
                }
            }*/
        }
        .onReceive(self.light.objectWillChange) {
            do {
                print("saving data")
                try self.managedObjectContext.save()
            } catch let e as NSError {
                print(e)
            }
        }
    }
}

struct UniverseDetailView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @ObservedObject var universe: Universe
    
    private let netOptions = [Int16](0...127)
    private let subnetOptions = [Int16](0...255)
    
    var body: some View {
        Form {
            Picker("Net", selection: $universe.net) {
                ForEach(netOptions, id: \.self) { option in
                    Text("\(option)")
                }
            }
            Picker("Sub-Net", selection: $universe.subnet) {
                ForEach(subnetOptions, id: \.self) { option in
                    Text("\(option)")
                }
            }
            NumberField("Light Points", value: $universe.numberOfLightPoints)
        }
        .onReceive(self.universe.objectWillChange) {
            do {
                print("saving universe")
                try self.managedObjectContext.save()
            } catch let e as NSError {
                print(e)
            }
        }
    }
}

struct UniverseListView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @ObservedObject var light: Light
    @State var selection : UUID? = nil
    
    var body: some View {
        List {
            ForEach(light.universes, id: \.id) { universe in
                NavigationLink(destination: UniverseDetailView(universe: universe), tag: universe.id, selection: self.$selection) {
                    Text("Net: \(universe.net) SubNet: \(universe.subnet)")
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    self.managedObjectContext.delete(self.light.universes[index])
                }
            }
        }
        .navigationBarTitle(Text("Universes"), displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
                let universe = Universe(context: self.managedObjectContext)
                universe.id = UUID()

                self.light.addToUniverses(universe)
                try! self.managedObjectContext.save()
                
                self.selection = universe.id
            }, label: {
            Image(systemName: "plus")
                .resizable()
                .frame(width: 24, height: 24, alignment: .center)
        }))
    }
}

struct LightDetail_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
         
        let light = Light(context: context)
        light.id = UUID()
        light.name = "Led Spots"
        light.ipAddress = IpAddress(192,168,1,255)

        return LightDetailView(light: light).environment(\.managedObjectContext, context)
    }
}
