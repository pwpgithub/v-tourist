//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Ping Wu on 3/5/18.
//  Copyright © 2018 SHDR. All rights reserved.
//

import UIKit
import MapKit
import CoreData

// MARK: - PhotoAlbumViewController: UIViewController

class PhotoAlbumViewController: UIViewController {
    
    // MRRK: Properties
    
    var photoStore: PhotoStore!
    
    var pin: Pin!
    var pinAnnotation: MKPointAnnotation!
    
    let photoDataSource = PhotoDataSource()

    
    // MARK: Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var noImagesLabel: UILabel!
    
    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
    
        if pin != nil {
            noImagesLabel.isHidden = pin.hasImages
        }
        
        updateDataSource()
        configureCollectionView()
        updateNewCollectionButtonTitle()
        setMapViewUI()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       
        collectionView.reloadData()
    }
    
    
    // MARK: Actions
    
    @IBAction func newCollectionPressed(_ sender: UIButton) {
        
        if newCollectionButton.currentTitle == "Remove Selected Pictures" {
            newCollectionButton.setTitle("New Collection", for: .normal)
            deleteSelectedPhotos()
        } else {
         
            newCollectionButton.isEnabled = false
            newCollectionButton.titleLabel?.alpha = 0.5
            
            for photo in photoDataSource.photos {
                photoStore.deletePhoto(photo: photo)
            }
            
            collectionView.reloadData()
            photoStore.fetchPhotosSearch(pin: pin, completion: { (photosResult) in
                
                self.collectionView.reloadData()
                self.updateDataSource()
                
            })
        }
    }
    
    func deleteSelectedPhotos() {
        
        if let selectedIndexPaths = collectionView.indexPathsForSelectedItems {

            for selectedIndexPath in selectedIndexPaths {
                
                let photo = photoDataSource.photos[selectedIndexPath.row]
                self.photoStore.deletePhoto(photo: photo)
                collectionView.reloadItems(at: [selectedIndexPath])
            }
        }
        
        updateDataSource()
        updateNewCollectionButtonTitle()
    }
}


// MARK: - PhotoAlbumViewController (Helpers)
extension PhotoAlbumViewController {
    
    func updateDataSource() {
        
        self.photoStore.fetchAllPhotos(pin: pin) { (photosResult) in
            switch photosResult {
            case let .success(photos):
                self.photoDataSource.photos = photos
            case .failure( _ ):
                self.photoDataSource.photos.removeAll()
            }
            self.collectionView.reloadSections(IndexSet(integer: 0))
        }
    }
}


// MARK: - PhotoAlbumViewController: UICollectionViewDelegate
extension PhotoAlbumViewController: UICollectionViewDelegate {
    
    // Did deselected
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        updateNewCollectionButtonTitle()
        
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
        cell.opaqueView.isHidden = true
    }
    
    // Did selected
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        updateNewCollectionButtonTitle()
        
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
        cell.opaqueView.isHidden = false
    }
    
    // will display
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
       
        self.newCollectionButton.isEnabled = false
        self.newCollectionButton.titleLabel?.alpha = 1.0
        let photo = photoDataSource.photos[indexPath.row]
        
        photoStore.fetchImageData(for: photo) { (imageDataResult) in
            
            guard let photoIndex = self.photoDataSource.photos.index(of: photo),
                case let .success(imageData) = imageDataResult,
                //let imageData = photo.imageData,
        
                let image = UIImage(data: imageData) else {
                    return
            }
        
            let photoIndexPath = IndexPath(item: photoIndex, section: 0)
            
            if let cell = self.collectionView.cellForItem(at: photoIndexPath) as? PhotoCollectionViewCell {
                
                cell.update(with: image)
                
                if  ((indexPath.row + 1) % collectionView.visibleCells.count) > 0  {
                    self.newCollectionButton.isEnabled = true
                    self.newCollectionButton.titleLabel?.alpha = 1.0
                    collectionView.setNeedsDisplay()
                }
            }
        }
    }
}


// MARK: - PhotoAlbumViewController: MKMapViewDelegate
extension PhotoAlbumViewController: MKMapViewDelegate {
    
    // pin view
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let userLocation = mapView.userLocation
        if userLocation.coordinate.latitude != annotation.coordinate.latitude || userLocation.coordinate.longitude != annotation.coordinate.longitude {
        let reuseID = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.tintColor = .red
        } else {
            pinView?.annotation = annotation
        }
        return pinView
        } else {
            return nil
        }
    }
}

// MARK: - PhotoAlbumViewController (Configure UI)
extension PhotoAlbumViewController {
    
    
    fileprivate func configureCollectionView() {
        collectionView.dataSource = photoDataSource
        collectionView.delegate = self
        
        collectionView.allowsMultipleSelection = true
    }
    
    fileprivate func updateNewCollectionButtonTitle() {
        if let indexPaths = collectionView.indexPathsForSelectedItems, indexPaths.isEmpty {
            
            newCollectionButton.setTitle("New Collection", for: .normal)
            newCollectionButton.isEnabled = false
            newCollectionButton.titleLabel?.alpha = 0.5
        } else {
            newCollectionButton.setTitle("Remove Selected Pictures", for: .normal)
            newCollectionButton.isEnabled = true
            newCollectionButton.titleLabel?.alpha = 1.0
        }
    }
    
    func setMapViewUI() {
        mapView.isZoomEnabled = true
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        mapView.isScrollEnabled = true
        
        mapView.showsCompass = true
        mapView.showsPointsOfInterest = true
        mapView.showsTraffic = true
        mapView.showsUserLocation = true
        
        let coordinate = pinAnnotation.coordinate
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpanMake(0.65, 0.65))
        mapView.addAnnotation(pinAnnotation)
        mapView.setRegion(region, animated: true)
    }
}
