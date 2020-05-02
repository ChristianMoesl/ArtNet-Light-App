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
public class Light: NSManagedObject {
    
}

extension Light {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Light> {
        return NSFetchRequest<Light>(entityName: "Light")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged private var alpha: Double
    @NSManaged private var red: Double
    @NSManaged private var green: Double
    @NSManaged private var blue: Double
    @NSManaged private var channelNumber_: Int16
    @NSManaged private var channelBlue: Int16
    @NSManaged private var channelGreen: Int16
    @NSManaged private var channelRed: Int16
    @NSManaged private var channelWhite: Int16
    @NSManaged private var ipAddress0: Int16
    @NSManaged private var ipAddress1: Int16
    @NSManaged private var ipAddress2: Int16
    @NSManaged private var ipAddress3: Int16
    @NSManaged private var universes_: NSOrderedSet

}

// MARK: Generated accessors for universes
extension Light {

    @objc(insertObject:inUniversesAtIndex:)
    @NSManaged public func insertIntoUniverses(_ value: Universe, at idx: Int)

    @objc(removeObjectFromUniversesAtIndex:)
    @NSManaged public func removeFromUniverses(at idx: Int)

    @objc(insertUniverses:atIndexes:)
    @NSManaged public func insertIntoUniverses(_ values: [Universe], at indexes: NSIndexSet)

    @objc(removeUniversesAtIndexes:)
    @NSManaged public func removeFromUniverses(at indexes: IndexSet)

    @objc(replaceObjectInUniversesAtIndex:withObject:)
    @NSManaged public func replaceUniverses(at idx: Int, with value: Universe)

    @objc(replaceUniversesAtIndexes:withUniverses:)
    @NSManaged public func replaceUniverses(at indexes: IndexSet, with values: [Universe])

    @objc(addUniversesObject:)
    @NSManaged public func addToUniverses(_ value: Universe)

    @objc(removeUniversesObject:)
    @NSManaged public func removeFromUniverses(_ value: Universe)

    @objc(addUniverses:)
    @NSManaged public func addToUniverses(_ values: NSOrderedSet)

    @objc(removeUniverses:)
    @NSManaged public func removeFromUniverses(_ values: NSOrderedSet)
}

extension Light {
    
    var channelNumber: Int {
        set { channelNumber_ = Int16(newValue) }
        get { Int(channelNumber_) }
    }

    var ipAddress: IpAddress {
        set {
            let converted = newValue.rawValues.map{ Int16($0) }
            ipAddress0 = converted[0]
            ipAddress1 = converted[1]
            ipAddress2 = converted[2]
            ipAddress3 = converted[3]
        }
        get {
            let converted = [ipAddress0, ipAddress1, ipAddress2, ipAddress3].map{ Int($0) }
            return IpAddress(converted[0], converted[1], converted[2], converted[3])
        }
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
    
    var universes: [Universe] {
        universes_.array as! [Universe]
    }
}
