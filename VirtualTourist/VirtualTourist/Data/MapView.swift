//
//  MapView.swift
//  VirtualTourist
//
//  Created by Lucas Stern on 09/07/2018.
//  Copyright © 2018 Stern. All rights reserved.
//

import Foundation
import MapKit

class MapView {
    
    private init() {}
    
    class func setDefaults(toSetMapView: MKMapView) {
        // For first time launch, the hasPreviousState will be false
        let hasPreviousState = UserDefaults.standard.bool(forKey: "hasPreviousState")
        
        // If the flag is set, values are saved in UserDefaults and we are free to use those
        if hasPreviousState {
            let latDouble = UserDefaults.standard.double(forKey:"lat")
            let lngDouble = UserDefaults.standard.double(forKey:"lng")
            let altInt = UserDefaults.standard.integer(forKey:"alt")
            
            toSetMapView.centerCoordinate.latitude = CLLocationDegrees(latDouble)
            toSetMapView.centerCoordinate.longitude = CLLocationDegrees(lngDouble)
            toSetMapView.camera.altitude = CLLocationDistance(altInt)
        }
    }
    
    class func saveDefaults(toSaveMapView: MKMapView) {
        // Get current state values from map
        let lat = toSaveMapView.centerCoordinate.latitude
        let lng = toSaveMapView.centerCoordinate.longitude
        let alt = toSaveMapView.camera.altitude
        
        // Save them in user defaults
        UserDefaults.standard.set(Double(lat), forKey: "lat")
        UserDefaults.standard.set(Double(lng), forKey: "lng")
        UserDefaults.standard.set(Int64(alt), forKey: "alt")
        // Set flag to show that the app have a previous state saved
        UserDefaults.standard.set(true, forKey: "hasPreviousState")
    }
}
