//
//  LightSettingsView.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 13.04.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import SwiftUI

struct LightSettingsView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(entity: LightEntity.entity(), sortDescriptors: []) var lights: FetchedResults<LightEntity>
    @State var selection : UUID? = nil
    
    var body: some View {
        List {
            ForEach(lights, id: \.id) { light in
                NavigationLink(destination: LightDetailView(light: light), tag: light.id!, selection: self.$selection) {
                    VStack(alignment: .leading) {
                        Text(light.name!)
                        Text("Net: \(light.net) Sub-Net: \(light.subnet)")
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
        .navigationBarTitle(Text("Lights"))
        .navigationBarItems(trailing: Button(action: {
                let light = LightEntity(context: self.managedObjectContext)
                light.id = UUID()
                light.name = ""
                light.ipAddress0 = 0
                light.ipAddress1 = 0
                light.ipAddress2 = 0
                light.ipAddress3 = 0
                light.net = 0
                light.subnet = 0

                try? self.managedObjectContext.save()

                self.selection = light.id
            }, label: {
                Image(systemName: "plus.circle")
                .resizable()
                    .frame(width: 32, height: 32, alignment: .center)
            })
        )
    }
}

struct LightSettingsView_Previews: PreviewProvider {
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

        return LightSettingsView().environment(\.managedObjectContext, context)
    }
}
