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
    var light: LightEntity
    
    typealias IpAddress = (Int, Int, Int, Int)
    
    // Input
    @Published var ipAddressField: String
    @Published var channelAssignmentFor3: [ColorChannel]
    @Published var channelAssignmentFor4: [ColorChannel]
    
    // Output
    @Published private(set) var ipAddressValid = true
    
    private var cancellableSet: Set<AnyCancellable> = []
    
    private func saveIPAddress(address: IpAddress) {
        let ip = (Int16(address.0), Int16(address.1), Int16(address.2), Int16(address.3))
        
        if self.light.ipAddress0 != ip.0 || self.light.ipAddress1 != ip.1
            || self.light.ipAddress2 != ip.2 || self.light.ipAddress3 != ip.3 {
            self.light.ipAddress0 = ip.0
            self.light.ipAddress1 = ip.1
            self.light.ipAddress2 = ip.2
            self.light.ipAddress3 = ip.3
        }
    }
    
    private func parseIPAddress(text: String) -> IpAddress? {
        let number = "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
        let regex = "^\(number).\(number).\(number).\(number)$"
        let matches = text.groups(for: regex)
        
        return matches.count == 0 ?
            nil : (Int(matches[0][1])!, Int(matches[0][2])!, Int(matches[0][3])!, Int(matches[0][4])!)
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
    

    init(light: LightEntity) {
        self.light = light
        self.ipAddressField = "\(light.ipAddress0).\(light.ipAddress1).\(light.ipAddress2).\(light.ipAddress3)"
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
    @ObservedObject var light: LightEntity
    
    @ObservedObject var viewModel: LightDetailViewModel

    init(light: LightEntity) {
        self.light = light
        self.viewModel = LightDetailViewModel(light: light)
    }
    
    private let channels3Options = permute(items: [ColorChannel.red, ColorChannel.green, ColorChannel.blue])
    private let channels4Options = permute(items: [ColorChannel.red, ColorChannel.green, ColorChannel.blue, ColorChannel.white])
    private let netOptions = [Int16](0...127)
    private let subnetOptions = [Int16](0...255)

    var body: some View {
        Form {
            Section(header: Text(LocalizedStringKey("Name"))) {
                TextField(LocalizedStringKey("Name"), text: $light.name_)
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
            }
            Section(header: Text("ArtNet")) {
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
            }
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

struct LightDetail_Previews: PreviewProvider {
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

        return LightDetailView(light: light).environment(\.managedObjectContext, context)
    }
}
