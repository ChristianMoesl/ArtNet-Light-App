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
            Text(value).multilineTextAlignment(.trailing)
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
