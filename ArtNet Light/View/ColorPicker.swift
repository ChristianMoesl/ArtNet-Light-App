//
//  ColorPicker.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 12.04.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import UIKit
import SwiftUI
import SwiftHSVColorPicker

protocol MyColorPickerDelegate: class {
    func colorDidChange(color: UIColor)
}

class MyColorPicker: SwiftHSVColorPicker {

    override var color: UIColor! {
        didSet {
            delegate?.colorDidChange(color: color)
        }
    }
    weak var delegate: MyColorPickerDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ColorPicker: UIViewRepresentable {
    typealias UIViewType = MyColorPicker
    
    let frame: CGRect
    @Binding var color: UIColor

    func makeUIView(context: Context) -> MyColorPicker {
        let view = MyColorPicker(frame: frame)
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: MyColorPicker, context: Context) {
        if uiView.color == nil || uiView.color != color {
            uiView.setViewColor(color)
        }
    }
    
    func makeCoordinator() -> ColorPicker.Coordinator {
        Coordinator(self)
    }
    
    static func dismantleUIView(_ uiView: MyColorPicker, coordinator: Coordinator) {
        uiView.delegate = nil
    }

    final class Coordinator: NSObject, MyColorPickerDelegate {
        private let pickerView: ColorPicker

        init(_ pickerView: ColorPicker) {
            self.pickerView = pickerView
        }

        func colorDidChange(color: UIColor) {
            pickerView.color = color
        }
    }
}

/*struct ColorPicker_Previews: PreviewProvider {
    static var previews: some View {
        ColorPicker(color: .constant(UIColor.white))
    }
}*/
