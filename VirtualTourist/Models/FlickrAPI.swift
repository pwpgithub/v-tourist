//
//  FlickrAPI.swift
//  VirtualTourist
//
//  Created by Ping Wu on 3/5/18.
//  Copyright © 2018 SHDR. All rights reserved.
//

import Foundation
import CoreData

enum Method: String {
    case photosSearch = "flickr.photos.search"
}

enum FlickrError: Error {
    case invalidJSONData
}

// MARK: FlickrAPI

class FlickrAPI {

    private static let session = URLSession.shared
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
   
    
    static func photosSearchURL(pin: Pin, currentPage: String) -> URL {
        
        let boundingBox = bbox(latitude: pin.latitude, longitude: pin.longitude)
        
        let parameters = [FlickrAPI.FlickrParameterKeys.Extras : FlickrAPI.FlickrParameterValues.ExtrasM,
                          FlickrAPI.FlickrParameterKeys.BoundingBox : boundingBox,
                          FlickrAPI.FlickrParameterKeys.PageOfResults : currentPage,
                          FlickrAPI.FlickrParameterKeys.PhotosPerPage : FlickrAPI.FlickrParameterValues.PhotosPerPage]
        
        return flickrURL(method: .photosSearch, parameters: parameters)
    }
    
    static func bbox(latitude: Double, longitude: Double) -> String {
        
        let minLon = max(longitude - FlickrAPI.Flickr.SearchBBoxHalfLon, FlickrAPI.Flickr.PhotosSearchLonRange.0)
        let minLat = max(latitude - FlickrAPI.Flickr.SearchBBoxHalfLat, FlickrAPI.Flickr.PhotosSearchLatRange.0)
        let maxLon = min(longitude + FlickrAPI.Flickr.SearchBBoxHalfLon, FlickrAPI.Flickr.PhotosSearchLonRange.1)
        let maxLat = min(latitude + FlickrAPI.Flickr.SearchBBoxHalfLat, FlickrAPI.Flickr.PhotosSearchLatRange.1)
        
        return "\(minLon),\(minLat),\(maxLon),\(maxLat)"
    }
    
    
    private class func flickrURL(method: Method, parameters: [String : String]?) -> URL {
        var components = URLComponents()
        components.scheme = FlickrAPI.Flickr.APIScheme
        components.host = FlickrAPI.Flickr.APIHost
        components.path = FlickrAPI.Flickr.APIPath
        
        var queryItems = [URLQueryItem]()
        
        let baseParams = [FlickrAPI.FlickrParameterKeys.Method : method.rawValue,
                          FlickrAPI.FlickrParameterKeys.Format : FlickrAPI.FlickrParameterValues.ResponseFormat,
                          FlickrAPI.FlickrParameterKeys.NoJSONCallback : FlickrAPI.FlickrParameterValues.DisableJSONCallback,
                          FlickrAPI.FlickrParameterKeys.APIKey : FlickrAPI.FlickrParameterValues.APIKey
        ]
        
        for (key, value) in baseParams {
            let item = URLQueryItem(name: key, value: value)
            queryItems.append(item)
        }
        
        if let additionalParams = parameters {
            for (key, value) in additionalParams {
                let item = URLQueryItem(name: key, value: value)
                queryItems.append(item)
            }
        }
        components.queryItems = queryItems
        
        return components.url!
    }
    
    
    
    class func photos(pin: Pin, fromJSON data: Data, into workingContext: NSManagedObjectContext) -> PhotosResult {
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDictionary = jsonObject as? [AnyHashable : Any],
                let photos = jsonDictionary[FlickrAPI.FlickrResponseKeys.Photos_Dic] as? [String : Any],
                let photosArray = photos[FlickrAPI.FlickrResponseKeys.Photo_Arr] as? [[String : Any]] else {
                    
                return .failure(FlickrError.invalidJSONData)
            }
            
            guard let totalPhotos = photos[FlickrAPI.FlickrResponseKeys.TotalPhotos] as? String else {
                return .failure(PhotoError.imageCreationError)
            }
            
            
            guard totalPhotos != "0" else {
                pin.hasImages = false
                try? pin.managedObjectContext?.save()
                return .failure(PhotoError.noImageError)
            }
            
            var finalPhotos = [Photo]()
            for photoJSON in photosArray {
                if let photo = photo(pin: pin, fromJSON: photoJSON, into: workingContext) {
                    finalPhotos.append(photo)
                }
            }
            
            if finalPhotos.isEmpty && !photosArray.isEmpty {
                return .failure(FlickrError.invalidJSONData)
            }
            
            return .success(finalPhotos)
        } catch {
            return .failure(error)
        }
    }
    
    
    private class func photo(pin: Pin, fromJSON json: [String : Any], into context: NSManagedObjectContext) -> Photo? {
        
        guard let photoID = json[FlickrAPI.FlickrResponseKeys.PhotoID] as? String,
            let dateString = json[FlickrAPI.FlickrResponseKeys.DateTaken] as? String,
            let urlString = json[FlickrAPI.FlickrResponseKeys.ExtrasM] as? String,
            let dateTaken = dateFormatter.date(from: dateString),
            let imageURL = URL(string: urlString) else {
                return nil
        }
   
        
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "\(#keyPath(Photo.photoID)) == \(photoID)")
        fetchRequest.predicate = predicate
        
        var fetchedPhotos: [Photo]?
        context.performAndWait {
            fetchedPhotos = try? fetchRequest.execute()
        }
        
        if let existingPhoto = fetchedPhotos?.last {
            return existingPhoto
        }
        
        var photo: Photo!
        if let pinContext = pin.managedObjectContext {
        context.performAndWait {
            
            photo = Photo(context: pinContext)
            photo.photoID = photoID
            photo.dateTaken = dateTaken
            photo.imageURL = imageURL as NSURL
            photo.pin = pin
        }
        }
        return photo
    }
}

