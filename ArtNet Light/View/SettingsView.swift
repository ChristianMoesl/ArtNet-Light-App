//
//  SettingsView.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 13.04.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(entity: Light.entity(), sortDescriptors: []) var lights: FetchedResults<Light>
    @State var selection : UUID? = nil
    
    var body: some View {
        Form {
            Section(header: Text("Lights"), footer: Button(action: {
                let light = Light(context: self.managedObjectContext)
                light.id = UUID()

                try! self.managedObjectContext.save()
                
                self.selection = light.id
            }, label: { Text("Add").font(.callout) })) {
                List {
                    ForEach(lights, id: \.id) { light in
                        NavigationLink(destination: LightDetailView(light: light), tag: light.id, selection: self.$selection) {
                            VStack(alignment: .leading) {
                                Text(light.name)
                                Text("IP: \(light.name)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            self.managedObjectContext.delete(self.lights[index])
                        }
                    }
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

struct SettingsView_Previews: PreviewProvider {

    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let light = Light(context: context)
        light.id = UUID()
        light.name = "Led Spots"
        light.ipAddress = IpAddress(192,168,1,255)

        return SettingsView().environment(\.managedObjectContext, context)
    }
}
