//
//  Universe+CoreDataProperties.swift
//  
//
//  Created by Christian Mösl on 01.05.20.
//
//

import Foundation
import CoreData

@objc(Universe)
public class UniverseEntity: NSManagedObject {

}

extension UniverseEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UniverseEntity> {
        return NSFetchRequest<UniverseEntity>(entityName: "UniverseEntity")
    }

    @NSManaged public var net: Int16
    @NSManaged public var subnet: Int16
    @NSManaged public var numOfLightPoints: Int16
    @NSManaged public var id: UUID?
}
