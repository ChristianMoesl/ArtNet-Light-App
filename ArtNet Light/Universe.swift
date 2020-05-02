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
public class Universe: NSManagedObject {

}

extension Universe {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Universe> {
        return NSFetchRequest<Universe>(entityName: "Universe")
    }

    @NSManaged private var net_: Int16
    @NSManaged private var subnet_: Int16
    @NSManaged private var numOfLightPoints_: Int16
    @NSManaged public var id: UUID
}

extension Universe {
    var net: Int {
        set { net_ = Int16(newValue) }
        get { Int(net_) }
    }
    
    var subnet: Int {
        set { subnet_ = Int16(newValue) }
        get { Int(subnet_) }
    }
    
    var numberOfLightPoints: Int {
        set { numOfLightPoints_ = Int16(newValue) }
        get { Int(numOfLightPoints_) }
    }
}

