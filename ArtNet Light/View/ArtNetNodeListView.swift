//
//  ArtNetNodeListView.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 30.04.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import SwiftUI

struct ArtNodeDetailView: View {
    let node: ArtNodeInfo
    
    var body: some View {
        Form {
            Info("Short Name", value: node.shortName)
            Info("IP Address", value: "\(node.ip.0).\(node.ip.1).\(node.ip.2).\(node.ip.3)")
            Info("MAC", value: node.mac.map{ String($0, radix: 16, uppercase: true) }.joined(separator: ":"))
            Info("Firmware Version", value: node.firmwareVersion)
            Info("Net Switch", value: node.net.description)
            Info("SubNet Switch", value: node.subNet.description)
            Info("SwIn Enabled", value: node.swInEnabled.map{ $0 ? "On " : "Off" }.joined(separator: " | "))
            Info("SwIn", value: node.swIn.map{ String($0, radix: 16, uppercase: true) }.joined(separator: " | "))
            Info("DHCP", value: node.dhcpOn ? "On" : "Off")
            Info("Long Name", value: node.longName)
            //Info("Node Report", value: node.nodeReport)
        }
    }
}

struct ArtNetNodeListView: View {
    @EnvironmentObject var artNet: ArtNetMaster
    @State var selection : UUID? = nil
    
    var body: some View {
        List {
            ForEach(artNet.nodes, id: \.id) { node in
                NavigationLink(destination: ArtNodeDetailView(node: node), tag: node.id, selection: self.$selection) {
                    VStack(alignment: .leading) {
                        Text(node.shortName)
                        Text("IP: \(node.ip.0).\(node.ip.1).\(node.ip.2).\(node.ip.3)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationBarTitle(Text("Node List"), displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
                self.artNet.pollNodes()
            }, label: {
                Image(systemName: "arrow.clockwise")
                    .resizable()
                    .frame(width: 24, height: 24, alignment: .center)
            })
        )
    }
}

struct ArtNetNodeListView_Previews: PreviewProvider {
    static var previews: some View {
        ArtNetNodeListView()
    }
}
