//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Ping Wu on 3/5/18.
//  Copyright © 2018 SHDR. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import Swift
import CoreLocation

let Has_Launched_Before = "hasLaunchedBefore"

// MRRK: - MapViewController: UIViewController, UIGestureRecognizerDelegate

class MapViewController: UIViewController, UIGestureRecognizerDelegate {
    
    // MARK: Properties
    var photoStore: PhotoStore!
    var allPins: [Pin] = []
    var allAnnotations = [MKPointAnnotation]()
    var currentMapView: MKMapView!
    var selectedPinView: MKPinAnnotationView!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let locationManager = CLLocationManager()
    var draggedPin: Pin!
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deletePinLabel: UILabel!
    @IBOutlet weak var editBarButtonItem: UIBarButtonItem!
    @IBOutlet var longPressGestureRecognizer: UILongPressGestureRecognizer!
    
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLocationManager()
        
        if UserDefaults.standard.bool(forKey: Has_Launched_Before) {
            restoreMapView()
        }

        let mapAnnotations = mapView.annotations
        mapView.removeAnnotations(mapAnnotations)
        
        updateAllPinsOnMap()
        setMapUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let pinView = selectedPinView {
            pinView.setSelected(true, animated: true)
        }
        
        if UserDefaults.standard.bool(forKey: Has_Launched_Before) {
            restoreMapView()
        }
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
       mapView.setNeedsDisplay()
        saveMapView()
    }
}

// MARK: MapViewController
extension MapViewController {
    
    func setupLocationManager() {
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            locationManager.requestAlwaysAuthorization()
            locationManager.requestLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
    }
    
    
    fileprivate func restoreMapView() {
        
        photoStore.fetchRestoreProperties { (result) in
            if case let .success(restore) = result {
                
                let lat = restore.latitude
                let lon = restore.longitude
                let spanLat = restore.spanLat
                let spanLon = restore.spanLon
                
                performUIUpdatesOnMain {
                    self.deletePinLabel.isHidden = restore.deletePinLabelIsHidden
                    self.editBarButtonItem.title = restore.editButtonTitle
                    self.longPressGestureRecognizer.isEnabled = restore.longPressIsEnabled
                }
                
                let center = CLLocationCoordinate2D(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(lon))
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpanMake(spanLat, spanLon))
                performUIUpdatesOnMain {
                    self.mapView.setRegion(region, animated: true)
                }
            }
        }
    }
    
    fileprivate func saveMapView() {
        mapView.setNeedsDisplay()
        let region = mapView.region
        
        let lat = region.center.latitude
        let lon = region.center.longitude
        
        let spanLat = region.span.latitudeDelta
        let spanLon = region.span.longitudeDelta
        
        let viewContext = photoStore.persistentContainer.viewContext
        
        photoStore.fetchRestoreProperties { (result) in
            if case let .success(restore) = result {
                viewContext.perform {
                    restore.latitude = lat
                    restore.longitude = lon
                    restore.spanLat = spanLat
                    restore.spanLon = spanLon
                    
                    performUIUpdatesOnMain {
                        restore.deletePinLabelIsHidden = self.deletePinLabel.isHidden
                        restore.longPressIsEnabled = self.longPressGestureRecognizer.isEnabled
                        restore.editButtonTitle = self.editBarButtonItem.title
                    }
                }
            }
        }
    }
}

// MARK: - MapViewController (Actions)
extension MapViewController {

    // MARK: Actions
    @IBAction func editPressed(_ sender: UIBarButtonItem) {
        
        editBarButtonItem.title == "Edit" ? (editBarButtonItem.title = "Done") : (editBarButtonItem.title = "Edit")
        
        photoStore.fetchRestoreProperties { (result) in
            if case let .success(restore) = result {
                performUIUpdatesOnMain {
                    restore.editButtonTitle = self.editBarButtonItem.title
                }
            }
        }
        
        updateDeleteLabelState()
    }
    
    // Long press to drop a pin and start download photos
    @IBAction func mapLongPressed(_ sender: UILongPressGestureRecognizer) {
       
        if longPressGestureRecognizer.state == UIGestureRecognizerState.began {
            print("Long Pressed")
            let pin = createAndDropPin()
            saveMapView()
            downloadPhotos(forPin: pin)
        }
    }
}


// MARK: - MapViewController (Helpers: Create and drop pin)
extension MapViewController {
    
    // update - refresh all pins on map
    fileprivate func updateAllPinsOnMap() {
        photoStore.fetchAllPins { (pinsResult) in
            
            switch pinsResult {
            case let .success(pins):
                self.allPins = pins
                let allAnnotations = self.getAnnotations(forPins: pins)
                performUIUpdatesOnMain {
                    let mapAnnotations = self.mapView.annotations
                    self.mapView.removeAnnotations(mapAnnotations)
                    self.mapView.addAnnotations(allAnnotations)
                }
            case .failure(_):
                self.allPins.removeAll()
                self.allAnnotations.removeAll()
                self.mapView.removeAnnotations(self.allAnnotations)
            }
        }
    }
    
    
    // get annotations from pins
    
    func getAnnotations(forPins pins: [Pin]) -> [MKPointAnnotation] {
        
        var annotations = [MKPointAnnotation]()
        
        for pin in pins {
            let lat = pin.latitude
            let lon = pin.longitude
            
            let coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(lat), CLLocationDegrees(lon))
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotations.append(annotation)
        }

        return annotations
    }
    
    func rounded(_ number: Double) -> Double {
        return Double(round(10000 * number) / 10000)
    }
    
    // get coordinate of pin dropped on map
    func coordinateOfPinDropped() -> CLLocationCoordinate2D {
        let longPressedPoint = self.longPressGestureRecognizer.location(in: self.mapView)
        
        let coordinate = self.mapView.convert(longPressedPoint, toCoordinateFrom: self.mapView)
        
        let annotaion = MKPointAnnotation()
        annotaion.coordinate = coordinate
        
        let region = MKCoordinateRegionMake(coordinate, MKCoordinateSpanMake(15.0, 15.0))
        
        self.mapView.addAnnotation(annotaion)
        self.mapView.setRegion(region, animated: true)
        
        return coordinate
    }
    
    
    // dorp pin on map and add it to context
    func createAndDropPin() -> Pin {
        
        let coordinate = coordinateOfPinDropped()
        
        let viewContext = photoStore.persistentContainer.viewContext
        let pinAddInContext = self.addPin(at: coordinate, into: viewContext)
        self.updateAllPinsOnMap()
        return pinAddInContext
    }
}

// MARK: - MapViewController (download Photos)

extension MapViewController {
    
    fileprivate func downloadPhotos(forPin pin: Pin) {
        self.photoStore.fetchPhotosSearch(pin: pin) { (photosResult) in
            if case let .success(photos) = photosResult {
                for photo in photos {
                    self.photoStore.fetchImageData(for: photo, completion: { (imageDataResult) in
                        print("downloading photos")
                    })
 
                }
            }
        }
    }
}


// MARK: - MapViewController (Access Context)
extension MapViewController {
    
    // add adn save pin to core data
    fileprivate func addPin(at coordinate: CLLocationCoordinate2D, into  context: NSManagedObjectContext) -> Pin {
        
        var pin: Pin!
        
        context.performAndWait {
            pin = Pin(context: context)
            pin.latitude = coordinate.latitude
            pin.longitude = coordinate.longitude
            pin.creationDate = Date()
            pin.pageNumber = 0
        }
        return pin
    }
    
    // delete pin from core data
    func deletePin(pin: Pin, from context: NSManagedObjectContext) {
        
        context.perform {
            context.delete(pin)
            
            do {
                try context.save()
                self.updateAllPinsOnMap()
            } catch {
                print("Error delete")
            }
        }
    }
}


// MARK: - MapViewController: CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let location = locations.last, !UserDefaults.standard.bool(forKey: Has_Launched_Before) {
            
            UserDefaults.standard.set(true, forKey: Has_Launched_Before)
            
            let coordinate = location.coordinate
            let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpanMake(18.0, 18.0))
            
            mapView.showsUserLocation = true
            mapView.setRegion(region, animated: true)
            
            let viewContext = photoStore.persistentContainer.viewContext
            
            viewContext.perform {
                
                let restore = Restore(context: viewContext)
                
                restore.latitude = region.center.latitude
                restore.longitude = region.center.longitude
                restore.spanLat = region.center.latitude
                restore.spanLon = region.center.longitude
                
                performUIUpdatesOnMain {
                    restore.deletePinLabelIsHidden = true
                    restore.longPressIsEnabled = true
                    restore.editButtonTitle = "Edit"
                }
            }
            
            manager.stopUpdatingLocation()
        }
    }
}


// MARK: - MapViewController: MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        
        if UserDefaults.standard.bool(forKey: Has_Launched_Before) {
            print("hasLaunched")
            saveMapView()
        }
    }
    
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {

        if UserDefaults.standard.bool(forKey: Has_Launched_Before) {
            print("hasLaunched")
            saveMapView()
        }
    }
    
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if UserDefaults.standard.bool(forKey: Has_Launched_Before) {
            saveMapView()
        }
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        if oldState == .starting && newState == .dragging {
    
            let latRounded = rounded((view.annotation?.coordinate.latitude)!)
            let lonRounded = rounded((view.annotation?.coordinate.longitude)!)
            
            for pin in allPins {
                if rounded(pin.latitude) == latRounded && rounded(pin.longitude) == lonRounded {
                    draggedPin = pin
                    break
                }
            }
        }
        
        
        if oldState == .dragging && newState == .ending {
           
            deletePin(pin: draggedPin, from: photoStore.persistentContainer.viewContext)
            
            draggedPin = addPin(at: (view.annotation?.coordinate)!, into: photoStore.persistentContainer.viewContext)
            
            let coordinate = view.annotation?.coordinate
            let region = MKCoordinateRegion(center: coordinate!, span: MKCoordinateSpanMake(15.0, 15.0))
            mapView.setRegion(region, animated: true)
            
            downloadPhotos(forPin: draggedPin)
        }
    }

    
    func pinSelected() -> Pin? {
        
        if let selectedAnnotation = mapView.selectedAnnotations.last {
            
            let latRounded = rounded(selectedAnnotation.coordinate.latitude)
            let lonRounded = rounded(selectedAnnotation.coordinate.longitude)
            
            
            for pin in allPins {
                if rounded(pin.latitude) == latRounded && rounded(pin.longitude) == lonRounded {
                    return pin
                }
            }
            return nil
        } else {
            return nil
        }
    }
    
    
    // pin did selected
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let annotaion = view.annotation
        
        let latRounded = rounded((annotaion?.coordinate.latitude)!)
        let lonRounded = rounded((annotaion?.coordinate.longitude)!)
        
        let userLatRounded = rounded(mapView.userLocation.coordinate.latitude)
        let userLongRounded = rounded(mapView.userLocation.coordinate.longitude)
  
        guard latRounded != userLatRounded || lonRounded != userLongRounded else {
            mapView.deselectAnnotation(view.annotation, animated: true)
            return
        }
        
        var pinSelected: Pin!
        
        for pin in allPins {
            if rounded(pin.latitude) == latRounded && rounded(pin.longitude) == lonRounded {
                pinSelected = pin
                break
            }
        }
        
        // selecte and delete pin
        if editBarButtonItem.title == "Done" {
            view.isSelected = false
            let viewContext = photoStore.persistentContainer.viewContext
            deletePin(pin: pinSelected, from: viewContext)
        } else { // navigate to collection view
            
            mapView.deselectAnnotation(view.annotation, animated: true)
            
            selectedPinView = view as! MKPinAnnotationView
            
            let photoAlbumVC = storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
            photoAlbumVC.photoStore = photoStore
            photoAlbumVC.pin = pinSelected
            photoAlbumVC.pinAnnotation = view.annotation as! MKPointAnnotation
            navigationController?.show(photoAlbumVC, sender: self)
        }
    }
    
    
    // create pinview
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseID = "pin"
        
        if mapView.userLocation.coordinate.latitude != annotation.coordinate.latitude || mapView.userLocation.coordinate.longitude != annotation.coordinate.longitude {
        
            var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        
            if pinView == nil {
                pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
                pinView?.tintColor = .red
                pinView?.isDraggable = true
            } else {
                pinView?.annotation = annotation
            }
        
            pinView?.setSelected(true, animated: true)
            return pinView
        } else {
            return nil
        }
    }
}

// MARK: - MapViewController (Configure UI)
extension MapViewController {
    
    func setMapUI() {
        deletePinLabel.isHidden = true
        
        mapView.isZoomEnabled = true
        mapView.isPitchEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = true
        
        mapView.showsCompass = true
        mapView.showsTraffic = true
        mapView.showsPointsOfInterest = true
        mapView.showsUserLocation = true
    }
    
    // configure delete label state
    func updateDeleteLabelState() {
        deletePinLabel.isHidden = editBarButtonItem.title == "Edit"
        longPressGestureRecognizer.isEnabled = editBarButtonItem.title == "Edit"
        photoStore.fetchRestoreProperties { (result) in
            if case let .success(restore) = result {
                self.photoStore.persistentContainer.viewContext.perform {
                performUIUpdatesOnMain {
                    restore.longPressIsEnabled = self.longPressGestureRecognizer.isEnabled
                    restore.deletePinLabelIsHidden = self.deletePinLabel.isHidden
                }
                }
            }
        }
    }
}
