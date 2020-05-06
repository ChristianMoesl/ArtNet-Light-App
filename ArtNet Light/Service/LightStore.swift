//
//  LightStore.swift
//  ArtNet Light
//
//  Created by Christian Mösl on 02.05.20.
//  Copyright © 2020 Christian Mösl. All rights reserved.
//

import Foundation
import CoreData
import SwiftUI
import Combine

class LightStore: NSObject, ObservableObject {

    // MARK: Public Properties
    
    public var lights: [Light] {
        return fetchedResultsController.fetchedObjects ?? []
    }

    private lazy var managedObjectContext: NSManagedObjectContext = {
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }()

    private lazy var fetchedResultsController: NSFetchedResultsController<Light> = {
        initializeFetchedResultsController(fetchRequest: Light.fetchRequest())
    }()
    
    private lazy var fetchedResultsControllerForUniverses: NSFetchedResultsController<Universe> = {
        initializeFetchedResultsController(fetchRequest: Universe.fetchRequest())
    }()
    
    // MARK: Public Methods
    
    func fetchLights() {
        do {
            try fetchedResultsController.performFetch()
            try fetchedResultsControllerForUniverses.performFetch()
        } catch {
            fatalError()
        }
    }
    
    func createLight() -> UUID {
        let light = Light(context: managedObjectContext)

        save()

        return light.id
    }
    
    func deleteLights(with indexSet: IndexSet) {
        for index in indexSet {
            managedObjectContext.delete(lights[index])
        }
    }
    
    func createUniverse(for light: Light) -> UUID {
        let universe = Universe(context: managedObjectContext)

        light.addToUniverses(universe)
        save()

        return universe.id
    }
    
    func deleteUniverses(for light: Light, indexSet: IndexSet) {
        for index in indexSet {
            let universe = light.universes[index]
            light.removeFromUniverses(universe)
            managedObjectContext.delete(universe)
        }
        save()
    }
    
    func save() {
        print("saving")
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let saveError = error as NSError
                print(saveError)
                fatalError()
            }
        }
    }
    
    // MARK: Private Methods
    
    private func initializeFetchedResultsController<T>(fetchRequest: NSFetchRequest<T>) -> NSFetchedResultsController<T> {
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "created", ascending: true)
        ]
        
        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: self.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }
    
    
}

// MARK: LightStore + NSFetchedResultsControllerDelegate
extension LightStore : NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        objectWillChange.send()
    }
}
