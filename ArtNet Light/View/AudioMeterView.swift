//
//  AudioMeterView.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 07.05.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import Foundation
import SwiftUI

struct AudioMeter: View {
    var decibels: Double
    var radius = 175
    
    private func decibels(at: Int) -> String {
        let vs = [84, 96, 108, 120, 0, 0, 12, 24, 36, 48, 60, 72]
        return vs[at] == 0 ? "" : "\(vs[at]) dB"
    }
    
    private var decibelsToTrim: CGFloat {
        let clamped = min(max(12.0, decibels), 120.0)
        return CGFloat((clamped - 12.0) / (120.0 - 12.0) * 0.75)
    }
    
    var body: some View {
        ZStack {
            Gauge(radius: radius, trim: 0.0...0.75)
            Gauge(radius: radius, trim: 0.0...decibelsToTrim)
                .maskContent(using: AngularGradient(gradient: Gradient(colors: [.blue, .green, .yellow, .red]), center: .center))
            ForEach(0...11, id: \.self) { i in
                Text(self.decibels(at: i))
                    .frame(maxHeight: .infinity, alignment: .top)
                    .rotationEffect(.degrees(Double(i * 30)))
            }
            Radar()
        }
        .frame(width: CGFloat(radius * 2), height: CGFloat(radius * 2))
    }
}

struct AudioMeterView_Previews: PreviewProvider {
    static var previews: some View {
        AudioMeter(decibels: 65.0)
    }
}

private struct Radar: View {
    var radius = 100
    
    private var outer: CGFloat { CGFloat(radius * 2) }
    private var middle: CGFloat { CGFloat(radius * 2 / 3 * 2)}
    private var inner: CGFloat { CGFloat(radius * 2 / 3) }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 1)
                .frame(width: outer, height: outer)
            Circle()
                .stroke(lineWidth: 1)
                .frame(width: middle, height: middle)
            Circle()
                .stroke(lineWidth: 1)
                .frame(width: inner, height: inner)
        }
    }
}

private func GapShapeMask(in rect: CGRect) -> Path {
    var shape = Rectangle().path(in: rect)
        .offsetBy(dx: CGFloat(-40), dy: CGFloat(-40))
    var o = Rectangle().size(width: CGFloat(0), height: CGFloat(0))
        .path(in: rect)
        .offsetBy(dx: CGFloat(175 - 40), dy: CGFloat(175 - 40))
    
    let off = CGPoint(x: 175 - 40 , y: 175 - 40)
    
    let radius = CGFloat(175)
    
    func addGap(with gap: Int, degrees: Int, in path: inout Path) {
        func point(_ degrees: Int) -> CGPoint {
            let d = Double(degrees) / 360.0 * 2 * .pi
            return CGPoint(x: CGFloat(cos(d)) * radius, y: CGFloat(sin(d)) * radius)
        }
        path.addLine(to: point(degrees - 1) + off)
        path.addLine(to: point(degrees + 1) + off)
        path.addLine(to: CGPoint(x: 0, y: 0) + off)
    }
    
    o.addLine(to: CGPoint(x: 0, y: 0) + off)
    
    for i in stride(from: 0, to: 359, by: 10) {
        addGap(with: 0, degrees: i, in: &o)
    }
    
    shape.addPath(o)
    return shape
}

private struct Gauge: View {
    var radius: Int
    var thickness: CGFloat = 20
    var trim: ClosedRange<CGFloat> = 0...1
    
    private var rect: CGRect {
        CGRect(x: 0, y: 0, width: CGFloat(radius * 2), height: CGFloat(radius * 2))
    }
    
    var body: some View {
        Circle()
            .trim(from: trim.lowerBound, to: trim.upperBound)
            .stroke(style: StrokeStyle(lineWidth: thickness))
            .rotation(.init(degrees: 90.0))
            .mask(GapShapeMask(in: rect).fill(style: FillStyle(eoFill: true)))
            .padding(40)
    }
}

/*private struct Graph: Shape {
    var values: [(Int, Float)]
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            let r = max(rect.height, rect.width) / 2
            let x = CGPoint(x: rect.midX, y: rect.midY)
            
            for (idx, value) in values {
                if idx == 0 {
                    path.move(to: )
                } else {
                    path.addLine(to: )
                }
            }
            path.closeSubpath()
        }
    }
}*/

