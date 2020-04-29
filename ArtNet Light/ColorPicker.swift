//
//  ColorPicker.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 12.04.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import SwiftUI
import SwiftHSVColorPicker

private class MyColorPicker: SwiftHSVColorPicker {
    override var color: UIColor! {
        didSet {
            colorBinding.wrappedValue = color
            colorBinding.update()
        }
    }
    private var colorBinding: Binding<UIColor>!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame: CGRect, colorBinding: Binding<UIColor>) {
        super.init(frame: frame)
        self.colorBinding = colorBinding
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ColorPicker: UIViewRepresentable {
    @Binding var color: UIColor
    
    func makeUIView(context: Context) -> SwiftHSVColorPicker {
        MyColorPicker(frame: CGRect(x: 0, y: 0, width: 300, height: 400), colorBinding: $color)
    }

    func updateUIView(_ uiView: SwiftHSVColorPicker, context: Context) {
        if uiView.color == nil {
            uiView.setViewColor(color)
        }
    }
}

struct ColorPicker_Previews: PreviewProvider {
    @State var color = UIColor.white
    static var previews: some View {
        ColorPicker(color: .constant(UIColor.white))
    }
}
