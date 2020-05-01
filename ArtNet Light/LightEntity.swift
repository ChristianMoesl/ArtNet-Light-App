//
//  Light+CoreDataProperties.swift
//  
//
//  Created by Christian Mösl on 01.05.20.
//
//

import Foundation
import CoreData
import SwiftUI

@objc(Light)
public class LightEntity: NSManagedObject {

}

extension LightEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LightEntity> {
        return NSFetchRequest<LightEntity>(entityName: "LightEntity")
    }

    @NSManaged public var alpha: Double
    @NSManaged public var blue: Double
    @NSManaged public var channelBlue: Int16
    @NSManaged public var channelGreen: Int16
    @NSManaged public var channelNumber: Int16
    @NSManaged public var channelRed: Int16
    @NSManaged public var channelWhite: Int16
    @NSManaged public var green: Double
    @NSManaged public var id: UUID?
    @NSManaged public var ipAddress0: Int16
    @NSManaged public var ipAddress1: Int16
    @NSManaged public var ipAddress2: Int16
    @NSManaged public var ipAddress3: Int16
    @NSManaged public var name: String?
    @NSManaged public var red: Double
    @NSManaged public var universes: NSSet?

}

// MARK: Generated accessors for universes
extension LightEntity {

    @objc(addUniversesObject:)
    @NSManaged public func addToUniverses(_ value: UniverseEntity)

    @objc(removeUniversesObject:)
    @NSManaged public func removeFromUniverses(_ value: UniverseEntity)

    @objc(addUniverses:)
    @NSManaged public func addToUniverses(_ values: NSSet)

    @objc(removeUniverses:)
    @NSManaged public func removeFromUniverses(_ values: NSSet)

}

extension LightEntity {
    
    var name_: String {
        get { name ?? "" }
        set { name = newValue }
    }
    
    var color: UIColor {
        set {
            let (r,g,b,a) = newValue.rgba

            red = Double(r)
            green = Double(g)
            blue = Double(b)
            alpha = Double(a)
        }
        get {
           return UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
        }
    }
    
    var channelAssignmentFor3: [ColorChannel] {
        set {
            let new = newValue + [.white]
            channelAssignmentFor4 = new
        }
        get {
            channelAssignmentFor4.filter{ $0 != .white }
        }
    }

    var channelAssignmentFor4: [ColorChannel] {
        set {
            for (idx, color) in newValue.enumerated() {
                let i = Int16(idx)
                switch color {
                case .red:
                    if channelRed != i { channelRed = i }
                case .green:
                    if channelGreen != i { channelGreen = i }
                case .blue:
                    if channelBlue != i { channelBlue = i }
                case .white:
                    if channelWhite != i { channelWhite = i }
                }
            }
        }
        get {
            [
                (ColorChannel.red, Int(channelRed)),
                (ColorChannel.green, Int(channelGreen)),
                (ColorChannel.blue, Int(channelBlue)),
                (ColorChannel.white, Int(channelWhite))
                ].sorted{ $0.1 < $1.1 }
            .map{ $0.0 }
        }
    }
    
    public var universeArray: [UniverseEntity] {
        let set = universes as? Set<UniverseEntity> ?? []
        return set.map{ $0 }
    }
}
