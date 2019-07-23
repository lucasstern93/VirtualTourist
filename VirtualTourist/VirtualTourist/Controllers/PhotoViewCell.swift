//
//  PhotoViewCell.swift
//  VirtualTourist
//
//  Created by Lucas Stern on 09/07/2018.
//  Copyright © 2018 Stern. All rights reserved.
//

import Foundation
import UIKit
class PhotoViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setPhoto(_ photo: Photo, onComplete: @escaping () -> Void) {
        if let data = photo.image {
            imageView.image = UIImage(data: data)
            onComplete()
        } else {
            imageView.image = #imageLiteral(resourceName: "placeholder_image")
            
            downloadImage(imagePath: photo.url!) { (imageData, error) in
                
                guard error == nil else {
                    debugPrint(error!)
                    return
                }
                
                guard let image = imageData else {
                    debugPrint("Download image error")
                    return
                }
                
                guard let convertedImage = UIImage(data: image) else {
                    debugPrint("Convert image error")
                    return
                }
                
                photo.image = UIImagePNGRepresentation(convertedImage)
                
                DispatchQueue.main.async {
                    self.imageView.image = convertedImage
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let context = appDelegate.dataController.viewContext
                    try? context.save()
                }
                
                onComplete()
            }
        }
    }
    
    func downloadImage( imagePath:String, completionHandler: @escaping (_ imageData: Data?, _ errorString: String?) -> Void){
        let session = URLSession.shared
        let imgURL = NSURL(string: imagePath)
        let request: NSURLRequest = NSURLRequest(url: imgURL! as URL)
        
        let task = session.dataTask(with: request as URLRequest) {data, response, downloadError in
            
            if downloadError != nil {
                completionHandler(nil, "Could not download image \(imagePath)")
            } else {
                
                completionHandler(data, nil)
            }
        }
        
        task.resume()
    }
}
