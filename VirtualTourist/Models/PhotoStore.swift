//
//  PhotoStore.swift
//  VirtualTourist
//
//  Created by Ping Wu on 3/5/18.
//  Copyright © 2018 SHDR. All rights reserved.
//

import UIKit
import CoreData


enum PhotoError: Error {
    case imageCreationError
    case noImageError
}


enum PhotosResult {
    case success([Photo])
    case failure(Error)
}

enum PinsResult {
    case success([Pin])
    case failure(Error)
}

enum ImageDataResult {
    case success(Data)
    case failure(Error)
}

enum RestorePropertyResult {
    case success(Restore)
    case failure(Error)
}

class PhotoStore {
    
    internal var dataController: DataController!
    
    var persistentContainer: NSPersistentContainer {
        return dataController.persistentContainer
    }
    
    let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    
    func deletePhoto(photo: Photo) {
        
        guard photo.photoID != nil else {
            return
        }
        
        persistentContainer.viewContext.performAndWait {
            persistentContainer.viewContext.delete(photo)
            try? persistentContainer.viewContext.save()
        }
    }
    
    
    func processImageData(data: Data?, error: Error?) -> ImageDataResult {
        
        guard let imageData = data else {
            return .failure(error!)
        }
        
        return .success(imageData)
    }
    
    
    func fetchImageData(for photo: Photo, completion: @escaping (ImageDataResult) -> Void) {
        
        guard photo.photoID != nil else {
            return
        }
        
        if let imageData = photo.imageData {
            performUIUpdatesOnMain {
                completion(.success(imageData))
            }
        }
        
        guard let imageURL = photo.imageURL else {
            return
        }
        
        let request = URLRequest(url: imageURL as URL)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            let result = self.processImageData(data: data, error: error)
            
            if case let .success(imageData) = result {
                
                photo.managedObjectContext?.performAndWait {
                    photo.imageData = imageData
                    try? photo.managedObjectContext?.save()
                }
            }
            
            performUIUpdatesOnMain {
                completion(result)
            }
        }
        
        task.resume()
    }
    
    
    func processPhotosRequest(pin: Pin, data: Data?, error: Error?, completion: @escaping (PhotosResult) -> Void) {
        
        guard let jsonData = data else {
            completion(.failure(error!))
            return
        }
        self.persistentContainer.performBackgroundTask { (workingContext) in
            
            let result = FlickrAPI.photos(pin: pin, fromJSON: jsonData, into: workingContext)
            
            do {
                try workingContext.save()
            } catch {
                print("Error saving to Core Data: \(error)")
                completion(.failure(error))
                return
            }
        
            switch result {
            case let .success(photos):
                let photoObjectIDs = photos.map { return $0.objectID }
                let viewContext = self.persistentContainer.viewContext
                let viewContextPhotos = photoObjectIDs.map { return viewContext.object(with: $0)} as! [Photo]
                completion(.success(viewContextPhotos))
            case .failure(_):
                completion(result)
            }
        }
    }
    
    
    func fetchRestoreProperties(completion: @escaping(RestorePropertyResult) -> Void) {
        
        let fetchRequest: NSFetchRequest<Restore> = Restore.fetchRequest()
        
        let viewContext = persistentContainer.viewContext
        
        viewContext.performAndWait {
            do {
                let restores = try viewContext.fetch(fetchRequest)
                if let restore = restores.last {
                    completion(.success(restore))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    
    func fetchAllPins(completion: @escaping(PinsResult) -> Void) {
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortByCreationDate = NSSortDescriptor(key: #keyPath(Pin.creationDate), ascending: false)
        fetchRequest.sortDescriptors = [sortByCreationDate]
        
        let viewContext = persistentContainer.viewContext
        
        viewContext.perform {
            do {
                let allPins = try viewContext.fetch(fetchRequest)
                completion(.success(allPins))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    
    func fetchAllPhotos(pin: Pin, completion: @escaping (PhotosResult) -> Void) {
        print("\npin: \(pin)\n")
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortByDateTaken = NSSortDescriptor(key: #keyPath(Photo.dateTaken), ascending: false)
        fetchRequest.sortDescriptors = [sortByDateTaken]
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        
        let viewContext = persistentContainer.viewContext
        
        viewContext.perform {
            do {
                let allPhotos = try viewContext.fetch(fetchRequest)
                completion(.success(allPhotos))
            } catch {
                print("error")
                completion(.failure(error))
            }
        }
    }
    
    
    func fetchPhotosSearch(pin: Pin, completion: @escaping (PhotosResult) -> Void) {
        print("\n\(#function)\n")
        pin.pageNumber += 1
        try? persistentContainer.viewContext.save()
        
        let url = FlickrAPI.photosSearchURL(pin: pin, currentPage: "\(pin.pageNumber)")
    
        let request = URLRequest(url: url)
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            print("in task")
            self.processPhotosRequest(pin: pin, data: data, error: error, completion: { (result) in
                
                performUIUpdatesOnMain {
                    completion(result)
                }
            })
        }
        task.resume()
    }
}

extension PhotoStore {
    class func sharedInstance() -> PhotoStore {
        struct Singleton {
            static var sharedInstance = PhotoStore()
        }
        return Singleton.sharedInstance
    }
}
