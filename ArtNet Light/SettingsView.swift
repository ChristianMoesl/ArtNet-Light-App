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
    @FetchRequest(entity: LightEntity.entity(), sortDescriptors: []) var lights: FetchedResults<LightEntity>
    @State var selection : UUID? = nil
    
    var body: some View {
        Form {
            Section(header: Text("Lights"), footer: Button(action: {
                let light = LightEntity(context: self.managedObjectContext)
                light.id = UUID()
                light.name = ""
                light.ipAddress0 = 0
                light.ipAddress1 = 0
                light.ipAddress2 = 0
                light.ipAddress3 = 0

                try? self.managedObjectContext.save()
                
                self.selection = light.id
            }, label: { Text("Add").font(.callout) })) {
                List {
                    ForEach(lights, id: \.id) { light in
                        NavigationLink(destination: LightDetailView(light: light), tag: light.id!, selection: self.$selection) {
                            VStack(alignment: .leading) {
                                Text(light.name!)
                                Text("IP: \(light.name!)")
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

        return SettingsView().environment(\.managedObjectContext, context)
    }
}
