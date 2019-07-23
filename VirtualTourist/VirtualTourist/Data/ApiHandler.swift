//
//  ApiHandler.swift
//  VirtualTourist
//
//  Created by Lucas Stern on 09/07/2018.
//  Copyright © 2018 Stern. All rights reserved.
//

import Foundation
import CoreData

class ApiHandler {
    
    let BASE_URL = "https://api.flickr.com/services/rest"
    var DICCONFIG: Dictionary<String, Any> = [
        "api_key": "e810b1825cb43ce5aaacc28d07078be1",
        "method" : "flickr.photos.search",
        "format" : "json",
        "extras": "url_m",
        "nojsoncallback" : 1,
        "accuracy": 6,
        "per_page": 30
    ]
    
    static let shared = ApiHandler()
    
    private init() {}
    
    func getPhotos(context: NSManagedObjectContext, place: Place, completion: @escaping (Errors?) -> Void) {
        
        let randomePage = Int(arc4random_uniform(UInt32(place.pageCount)))
        
        let requestUrl = generateUrl(place.latitude, place.longitude, page: Int16(randomePage))
        let request = URLRequest(url: requestUrl)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            
            if error != nil {
                debugPrint("Flickr error \(error.debugDescription)")
                // Handle error
                completion(Errors.NetworkError)
                return
            }
            
            let responseDict = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! NSDictionary
            if responseDict["stat"] as? String != "ok" || responseDict["photos"] == nil {
                print(Errors.ServerError)
                completion(Errors.ServerError)
                return
            }
            
            let results = responseDict["photos"] as! NSDictionary
            guard let per_page = self.DICCONFIG["per_page"] as? Int else {
                debugPrint("per_page error")
                // Handle error
                completion(Errors.UnknownError)
                return
            }
            
            let pages = results["pages"] as! Int16
            place.pageCount = min(pages, Int16(4000 / per_page))
            
            let photoArray = results["photo"] as! [NSDictionary]
            place.photos = NSSet()
            for photoDictionary in photoArray {
                let photo = Photo(context: context)
                photo.setFrom(photoDictionary)
                place.addToPhotos(photo)
            }
            
            do {
                try context.save()
                completion(nil)
            } catch let dbError {
                print("\(dbError.localizedDescription)")
                completion(Errors.DatabaseError)
            }
        })
        
        task.resume()
    }
    
    private func generateUrl(_ latitude: Double, _ longitude: Double, page: Int16) -> URL {
        DICCONFIG.updateValue(latitude, forKey: "lat")
        DICCONFIG.updateValue(longitude, forKey: "lon")
        DICCONFIG.updateValue(page, forKey: "page")
        
        var queryItems = [URLQueryItem]()
        for item in DICCONFIG {
            queryItems.append(URLQueryItem(name: item.key, value: String(describing: item.value)))
            print(item)
        }
        let urlComponent = NSURLComponents(string: BASE_URL)!
        urlComponent.queryItems = queryItems
        
        return urlComponent.url!
    }
}
