//
//  TravelMapViewController.swift
//  VirtualTourist
//
//  Created by Lucas Stern on 09/07/2018.
//  Copyright © 2018 Stern. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class TravelMapViewController: UIViewController {
    
    let reuseId = "pin"
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    
    var editModeOn = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set MKMapView Delegate
        mapView.delegate = self
        
        // Set LongPressListener for pins on the map
        let longPressGestureRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(onLongPressed(sender:)))
        mapView.addGestureRecognizer(longPressGestureRecogniser)
        
        // Fetch data from database
        let fetchRequest: NSFetchRequest<Place> = Place.fetchRequest()
        if let results = try? dataController.viewContext.fetch(fetchRequest) {
            editButton.isEnabled = results.count > 0
            for place in results {
                mapView.addAnnotation(place.getAnnotation())
            }
        }
        
        // Set up toolbar
        navigationController?.toolbar.barTintColor = UIColor(named: "PrimaryColor")
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let tapToDeleteButton = UIBarButtonItem(title: "Tap Pins to Delete", style: .plain, target: nil, action: nil)
        tapToDeleteButton.tintColor = UIColor.white
        toolbarItems = [spacer, tapToDeleteButton, spacer]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Set the camera to previous position
        MapView.setDefaults(toSetMapView: mapView)
    }
    
    @IBAction func onEditClicked(_ sender: Any) {
        if editModeOn {
            // End edit mode
            editModeOn = false
            editButton.image = UIImage(named: "icon_edit")
            navigationController?.isToolbarHidden = true
        } else {
            // Show edit mode
            editModeOn = true
            editButton.image = UIImage(named: "icon_done")
            navigationController?.isToolbarHidden = false
        }
        
        refreshMapAnnoatation()
    }
    
    @objc func onLongPressed(sender: UILongPressGestureRecognizer) {
        // If the gesture is in process, return
        if sender.state != .ended {
            return
        }
        
        // Get LocationCoordinates from touched point
        let touchPoint: CGPoint = sender.location(in: mapView)
        let touchCoordinates: CLLocationCoordinate2D = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let touchLocation = CLLocation(latitude: touchCoordinates.latitude, longitude: touchCoordinates.longitude)
        
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(touchLocation){
            [weak self] placemarks, error in
            if let placemark = placemarks?.first {
                
                if self == nil {
                    return
                }
                
                let place = Place(context: self!.dataController.viewContext)
                place.locationString = "\(placemark.name ?? ""), \(placemark.locality ?? "")"
                place.latitude = touchCoordinates.latitude
                place.longitude = touchCoordinates.longitude
                
                do {
                    // If data is saved, create annotation and add to MapView
                    try self!.dataController.viewContext.save()
                    self!.mapView.addAnnotation(place.getAnnotation())
                    self!.editButton.isEnabled = true
                    
                    // Open AlbumViewController
                    let albumViewController = PhotoAlbumViewController.getInstance(caller: self!, dataController: self!.dataController, place: place)
                    self!.navigationController?.pushViewController(albumViewController, animated: true)
                    
                } catch {
                    // Show database error
                    self!.showAlertDialog(title: "Error", message: "Local database error.", dismissHandler: nil)
                }
                
            } else {
                // Show Geocoding error
                self?.showAlertDialog(title: "Error", message: "No address found for the dropped pin. Try pinning again.", dismissHandler: nil)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Save the camera position when view is about to disappear
        MapView.saveDefaults(toSaveMapView: mapView)
    }
}

extension TravelMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        MapView.saveDefaults(toSaveMapView: mapView)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if !(annotation is MKPointAnnotation) {
            return nil
        }
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }  else {
            pinView!.annotation = annotation
        }
        
        if editModeOn {
        } else {
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("Annotation Seleacted")
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control != view.rightCalloutAccessoryView {
            return
        }
        
        // Get data form anntation
        let annotation = view.annotation
        let locationString = annotation?.title
        
        if editModeOn {
            // Delete pin and Place
            if let place = getPlace(locationString!!) {
                dataController.viewContext.delete(place)
                do {
                    // If data is saved, create annotation and add to MapView
                    try self.dataController.viewContext.save()
                    mapView.removeAnnotation(annotation!)
                } catch {
                    // Show database error
                    self.showAlertDialog(title: "Error", message: "Local database error.", dismissHandler: nil)
                }
                return
            }
        }
        
        // Open AlbumViewController
        if let place = getPlace(locationString!!) {
            let albumViewController = PhotoAlbumViewController.getInstance(caller: self, dataController: dataController, place: place)
            navigationController?.pushViewController(albumViewController, animated: true)
        }
    }
    
    private func getPlace(_ locationString: String) -> Place? {
        let fetchRequest: NSFetchRequest<Place> = Place.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "locationString = %@", locationString)
        if let results = try? dataController.viewContext.fetch(fetchRequest) {
            if results.count <= 0 {
                // No object found
                return nil
            }
            
            let place = results[0]
            return place
        }
        
        return nil
    }
    
    func refreshMapAnnoatation() {
        let annotations = mapView.annotations
        editButton.isEnabled = annotations.count > 0
        mapView.removeAnnotations(annotations)
        mapView.addAnnotations(annotations)
    }
}
