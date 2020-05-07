//
//  LightDetail.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 12.04.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import SwiftUI
import Combine

class LightDetailViewModel: ObservableObject, Identifiable {
    // Input
    @Published var ipAddressField: String
    @Published var channelAssignmentFor3: [ColorChannel]
    @Published var channelAssignmentFor4: [ColorChannel]
    @Published var selection: UUID? = nil
    
    // Output
    @Published private(set) var ipAddressValid = true
    @Published private(set) var universesViewModels = [UniverseDetailViewModel]()
    
    let id: UUID
    
    var name: String {
        get { light.name }
        set { light.name = newValue }
    }

    var channelNumber: Int {
        get { light.channelNumber }
        set { light.channelNumber = newValue }
    }
    
    var ipAddress: String {
        light.ipAddress.description
    }

    private var cancellableSet: Set<AnyCancellable> = []
    private var universeViewModelSubscriptions = [AnyCancellable]()
    private let lightStore: LightStore
    private let light: Light
    
    init(for light: Light, in lightStore: LightStore) {
        self.light = light
        self.id = light.id
        self.lightStore = lightStore
        self.ipAddressField = light.ipAddress.description
        self.channelAssignmentFor3 = light.channelAssignmentFor3
        self.channelAssignmentFor4 = light.channelAssignmentFor4
        
        updateUniverseViewModels()
        
        ipAddressValidator
            .receive(on: RunLoop.main)
            .map{ $0 != nil }
            .assignNoRetain(to: \.ipAddressValid, on: self)
            .store(in: &cancellableSet)
        
        ipAddressValidator
            .sink{ [weak self] result in
                if let address = result {
                    self?.saveIPAddress(address: address)
                }
        }
        .store(in: &cancellableSet)
        
        $channelAssignmentFor3.merge(with: $channelAssignmentFor4)
            .receive(on: RunLoop.main)
            .sink{ [weak self] assignments in self?.saveChannelAssignments(assignments: assignments) }
            .store(in: &cancellableSet)
        
        light.objectWillChange.sink { [weak self] _ in
            self?.updateUniverseViewModels()
            self?.objectWillChange.send()
        }.store(in: &cancellableSet)
    }
    
    func save() { lightStore.save() }
    
    func createUniverse() {
        selection = lightStore.createUniverse(for: light)
    }
    
    func deleteUniverses(_ indexSet: IndexSet) {
        lightStore.deleteUniverses(for: light, indexSet: indexSet)
    }
    
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
    
    private lazy var ipAddressValidator: AnyPublisher<IpAddress?, Never> = {
        $ipAddressField
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .removeDuplicates()
            .map{ [weak self] t in self?.parseIPAddress(text: t) }
            .eraseToAnyPublisher()
    }()
    
    private func saveChannelAssignments(assignments: [ColorChannel]) {
        if assignments.count == 4 && light.channelAssignmentFor4 != assignments {
            light.channelAssignmentFor4 = assignments
        } else if assignments.count == 3 && light.channelAssignmentFor3 != assignments {
            light.channelAssignmentFor3 = assignments
        }
    }

    private func updateUniverseViewModels() {
        universesViewModels = light.universes.map{ universe in
            if let matching = self.universesViewModels.filter({ $0.id == universe.id }).first {
                return matching
            } else {
                return UniverseDetailViewModel(for: universe, in: lightStore)
            }
        }

        universeViewModelSubscriptions = universesViewModels.map {
            $0.objectWillChange.sink{ [weak self] in self?.objectWillChange.send() }
        }
    }
}



struct LightDetailView: View {
    @ObservedObject var viewModel: LightDetailViewModel

    private let channels3Options = permute(items: ColorChannel.allCases.filter{ $0 != .white })
    private let channels4Options = permute(items: ColorChannel.allCases)

    var body: some View {
        Form {
            Section(header: Text("LIGHT")) {
                TextField(LocalizedStringKey("Name"), text: $viewModel.name)
                Stepper(value: $viewModel.channelNumber, in: 3...4, label: {
                    Text("Number of Channels: \(viewModel.channelNumber)")
                })
                if viewModel.channelNumber == 3 {
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
            Section(header: Text(LocalizedStringKey("NETWORK"))) {
                TextField("IP Address", text: $viewModel.ipAddressField)
                    .keyboardType(.numbersAndPunctuation)
                if !viewModel.ipAddressValid {
                    Text("IP address has wrong format")
                        .fontWeight(.light)
                        .font(.footnote)
                        .foregroundColor(Color.red)
                }
            }
            Section(header: Text("UNIVERSES"), footer: AddButton{ self.viewModel.createUniverse() }) {
                List {
                    ForEach(viewModel.universesViewModels, id: \.id) { universe in
                        NavigationLink(destination: UniverseDetailView(viewModel: universe), tag: universe.id, selection: self.$viewModel.selection) {
                            VStack(alignment: .leading) {
                                Text("\(universe.numberOfLightPoints)")
                                Text("Net: \(universe.net) SubNet: \(universe.subnet)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete {
                        self.viewModel.deleteUniverses($0)
                    }
                }
            }
        }
    }
}

