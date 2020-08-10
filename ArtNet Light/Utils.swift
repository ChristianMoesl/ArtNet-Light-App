//
//  Utils.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 25.04.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

extension UIColor {
    private func clamp(_ val: CGFloat) -> CGFloat {
        min(max(val, 0), 1)
    }
    public var rgba: (CGFloat, CGFloat, CGFloat, CGFloat) {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        if getRed(&r, green: &g, blue: &b, alpha: &a) {
            return (clamp(r), clamp(g), clamp(b), clamp(a))
        }
        return (0,0,0,0)
    }
    
    public var hsva: (CGFloat, CGFloat, CGFloat, CGFloat) {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        if getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return (clamp(h), clamp(s), clamp(b), clamp(a))
        }
        return (0, 0, 0, 0)
    }
}

extension String {
    func groups(for regexPattern: String) -> [[String]] {
        do {
            let text = self
            let regex = try NSRegularExpression(pattern: regexPattern)
            let matches = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return matches.map { match in
                return (0..<match.numberOfRanges).map {
                    let rangeBounds = match.range(at: $0)
                    guard let range = Range(rangeBounds, in: text) else {
                        return ""
                    }
                    return String(text[range])
                }
            }
        } catch let error {
            debugPrint("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}

extension Publisher where Self.Failure == Never {
    public func assignNoRetain<Root>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>, on object: Root) -> AnyCancellable where Root: AnyObject {
        sink { [weak object] (value) in
            object?[keyPath: keyPath] = value
        }
    }
}

extension View {
    func maskContent<T: View>(using: T) -> some View {
        using.mask(self)
    }
}

extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}
