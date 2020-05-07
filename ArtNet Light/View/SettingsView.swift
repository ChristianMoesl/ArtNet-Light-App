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
    
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
    
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
    
    func lightDetailLink(_ light: LightDetailViewModel) -> some View {
        NavigationLink(destination: LightDetailView(viewModel: light), tag: light.id, selection: self.$viewModel.selection) {
            VStack(alignment: .leading) {
                Text(light.name)
                Text("IP: \(light.ipAddress)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    var addLightButton: some View {
        HStack(alignment: .center) {
            Button(action: {
                self.viewModel.addLight()
            }, label: {
                Text("Add")
                    .font(.callout)
                    .frame(alignment: .center)
            })
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
        .padding(6)
    }

    var body: some View {
        VStack {
            Form {
                Section(header: Text("LIGHTS"), footer: AddButton{ self.viewModel.addLight() }) {
                    List {
                        ForEach(viewModel.lightDetails, id: \.id) { lightViewModel in
                            self.lightDetailLink(lightViewModel)
                        }
                        .onDelete { self.viewModel.deleteLights($0) }
                    }
                }
                Section(header: Text("ADVANCED")) {
                    NavigationLink(destination: ArtNetDiagnoseView()) {
                        Text("Configure Node Address")
                    }
                    NavigationLink(destination: ArtNetNodeListView()) {
                        Text("List Nodes")
                    }
                }
                Section(header: Text("ABOUT")) {
                    Info("Version", value: viewModel.appVersion)
                }
            }
        }
        .navigationBarTitle(Text("Settings"))
    }
}

