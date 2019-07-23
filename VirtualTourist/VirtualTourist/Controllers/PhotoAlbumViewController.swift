//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Lucas Stern on 09/07/2018.
//  Copyright © 2018 Stern. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    var refreshButton: UIBarButtonItem!
    
    var dataController: DataController!
    var place: Place!
    var album: [Photo] = [Photo]()
    var loadedImageCount: Int!
    
    let numberOfItems = 3
    let margin : CGFloat = 8
    let internalSpacing : CGFloat = 4
    
    // Instantiates PhotoAlbumViewController with given parameters.
    class func getInstance(caller: UIViewController, dataController: DataController, place: Place) -> PhotoAlbumViewController {
        // Instantiate VC from storyboard
        let albumViewController: PhotoAlbumViewController = caller.storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        // Set required parameters and return
        albumViewController.dataController = dataController
        albumViewController.place = place
        return albumViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Set the camera for map
        let locationCoordinates = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
        mapView.centerCoordinate = locationCoordinates
        mapView.region = MKCoordinateRegion(center: locationCoordinates, span: MKCoordinateSpanMake(0.2, 0.2))
        // Add a Pin
        let annotation = MKPointAnnotation()
        annotation.coordinate = locationCoordinates
        mapView.addAnnotation(annotation)
        
        // Set title
        title = place.locationString
        
        // Setup collection view controller
        self.collectionView.register(UINib(nibName: "PhotoViewCell", bundle: nil), forCellWithReuseIdentifier: "PhotoViewCell")
        
        // Setup toolbar
        navigationController?.toolbar.barTintColor = UIColor(named: "PrimaryColor")
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        refreshButton = UIBarButtonItem(image: UIImage(named: "icon_refresh"), style: .plain, target: self, action: #selector(forceRefreshImageSet))
        refreshButton.tintColor = UIColor.white
        refreshButton.isEnabled = false
        
        setToolbarItems([spacer, refreshButton, spacer], animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Show toolbar
        navigationController?.isToolbarHidden = false
        if !refreshImageSet() {
            forceRefreshImageSet()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Hide toolbar
        navigationController?.isToolbarHidden = true
        // Save data
        do {
            try dataController.viewContext.save()
        } catch {
            print("Data saving failed")
        }
    }
    
    @objc func forceRefreshImageSet() {
        setViewState(.LOADING_IMAGES)
        // Pass Context and Start loading images
        ApiHandler.shared.getPhotos(context: dataController.viewContext, place: place, completion: { error in
            // Handle error and show success case
            DispatchQueue.main.async {
                if error != nil {
                    self.showAlertDialog(title: "Error", message: (error!.rawValue), dismissHandler: nil)
                    return
                }
                self.setViewState(.IDLE)
                self.refreshImageSet()
            }
        })
    }
    
    func refreshImageSet() -> Bool {
        let photoSet: NSSet? = place.photos
        if photoSet != nil && photoSet?.count ?? 0 > 0 {
            album = Array(photoSet!) as! [Photo]
            loadedImageCount = 0
            self.collectionView.reloadData()
            self.setViewState(.IDLE)
            return true
        }
        return false
    }
    
    // MARK: View States
    
    enum ViewState {
        case LOADING_IMAGES
        case IDLE
    }
    
    func setViewState(_ viewState: ViewState) {
        
        switch viewState {
        case .LOADING_IMAGES:
            mapView.alpha = 0.5
            collectionView.isHidden = true
            indicatorView.isHidden = false
            indicatorView.startAnimating()
            refreshButton.isEnabled = false
            break
        case .IDLE:
            mapView.alpha = 1.0
            collectionView.isHidden = false
            indicatorView.isHidden = true
            indicatorView.stopAnimating()
            refreshButton.isEnabled = false
            break
        }
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return album.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Load Image
        let photo = album[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoViewCell", for: indexPath) as! PhotoViewCell
        cell.setPhoto(photo, onComplete: {
            self.loadedImageCount! += 1
            if self.loadedImageCount == self.album.count {
                self.refreshButton.isEnabled = true
            }
        })
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Delete photo
        let photo = album.remove(at: indexPath.row)
        dataController.viewContext.delete(photo)
        collectionView.reloadData()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.dataController.viewContext
        try? context.save()
    }
    
    // MARK:- UICollectionViewDelegateFlowLayout Methods
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = UIScreen.main.bounds.width
        let spacificWidth = (width - (2*margin + internalSpacing * CGFloat(numberOfItems - 1)))/CGFloat(numberOfItems)
        return CGSize(width: spacificWidth, height: spacificWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return internalSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return internalSpacing
    }
}
