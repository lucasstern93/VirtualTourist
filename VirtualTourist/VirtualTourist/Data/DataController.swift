//
//  DataController.swift
//  VirtualTourist
//
//  Created by Lucas Stern on 09/07/2018.
//  Copyright © 2018 Stern. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    
    let persistanceContainer: NSPersistentContainer
    
    init(modelName: String = "VirtualTourist") {
        self.persistanceContainer = NSPersistentContainer(name: modelName)
    }
    
    var viewContext: NSManagedObjectContext {
        return self.persistanceContainer.viewContext
    }
    
    func load(completion: (() -> Void)? = nil) {
        self.persistanceContainer.loadPersistentStores(completionHandler: {
            storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            
            completion?()
        })
    }
}
