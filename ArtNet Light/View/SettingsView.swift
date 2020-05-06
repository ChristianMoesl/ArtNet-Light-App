//
//  SettingsView.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 13.04.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    @Published var lightDetails = [LightDetailViewModel]()
    @Published var selection: UUID? = nil
    
    private let lightStore: LightStore
    private var cancellableSet: Set<AnyCancellable> = []

    init(_ lightStore: LightStore) {
        self.lightStore = lightStore
        self.lightDetails = prepareLightViewModels()
        
        lightStore.objectWillChange
            .sink(receiveValue: { [weak self] value in
                if let s = self {
                    s.lightDetails = s.prepareLightViewModels()
                }
            })
            .store(in: &cancellableSet)
    }
    
    func addLight() {
        selection = lightStore.createLight()
    }
    
    func deleteLights(_ indexSet: IndexSet) {
        lightStore.deleteLights(with: indexSet)
    }
    
    private func prepareLightViewModels() -> [LightDetailViewModel] {
        lightStore.lights.map{ light in
            if let matching = self.lightDetails.filter({ $0.id == light.id }).first {
                return matching
            } else {
                return LightDetailViewModel(for: light, in: lightStore)
            }
        }
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section(header: Text("Lights"), footer: Button(action: {
                self.viewModel.addLight()
            }, label: { Text("Add").font(.callout) })) {
                List {
                    ForEach(viewModel.lightDetails, id: \.id) { light in
                        NavigationLink(destination: LightDetailView(viewModel: light), tag: light.id, selection: self.$viewModel.selection) {
                            VStack(alignment: .leading) {
                                Text(light.name)
                                Text("IP: \(light.ipAddress)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { self.viewModel.deleteLights($0) }
                }
            }
            Section(header: Text("Advanced")) {
                NavigationLink(destination: ArtNetDiagnoseView()) {
                    Text("Configure Node Address")
                }
                NavigationLink(destination: ArtNetNodeListView()) {
                    Text("List Nodes")
                }
            }
        }
        .navigationBarTitle(Text("Settings"))
    }
}

