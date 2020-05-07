//
//  BasicViews.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 30.04.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import Foundation
import SwiftUI

struct NumberField: View {
    var number: Binding<Int>
    let text: LocalizedStringKey
    
    init(_ text: LocalizedStringKey, value: Binding<Int>) {
        self.text = text
        self.number = value
    }
    
    var body: some View {
        HStack {
            Text(text)
            TextField("", value: number, formatter: NumberFormatter())
                .multilineTextAlignment(.trailing)
        }
    }
}

struct Info: View {
    var text: LocalizedStringKey
    var value: String
    
    init(_ text: LocalizedStringKey, value: String) {
        self.text = text
        self.value = value
    }
    
    var body: some View {
        HStack {
            Text(text)
            Spacer()
            Text(value)
        }
    }
}

struct StringField: View {
    var text: LocalizedStringKey
    var value: Binding<String>
    
    init(_ text: LocalizedStringKey, value: Binding<String>) {
        self.text = text
        self.value = value
    }
    
    var body: some View {
        HStack {
            Text(text)
            TextField("", text: value)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct AddButton: View {
    var action: () -> Void
    
    init( _ action: @escaping () -> Void) {
        self.action = action
    }
    
    var body: some View {
        HStack(alignment: .center) {
            Button(action: action, label: {
                Text("Add")
                    .font(.callout)
                    .frame(alignment: .center)
            })
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
        .padding(6)
    }
}

struct BasicViews_Previews: PreviewProvider {
    static var previews: some View {
        return Form {
            NumberField("NumberField", value: .constant(123))
            Info("Info", value: "bla")
            StringField("StringField", value: .constant("Value"))
        }
    }
}

