//
//  FlickrConstants.swift
//  PWVirtualTourist
//
//  Created by Ping Wu on 2/9/18.
//  Copyright © 2018 SHDR. All rights reserved.
//

import Foundation

// MARK: - FlickrClient

extension FlickrAPI {
    
    // MAKR: Flickr
    
    struct Flickr {
        static let APIScheme = "https"
        static let APIHost = "api.flickr.com"
        static let APIPath = "/services/rest"
        
        static let SearchBBoxHalfLat = 0.5
        static let SearchBBoxHalfLon = 0.5
        static let PhotosSearchLatRange = (-90.0,90.0)
        static let PhotosSearchLonRange = (-180.0,180.0)
    }
    
    // MARK: Flickr Parameter Keys
    
    struct FlickrParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let SafeSearch = "safe_search"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let Extras = "extras"
        static let BoundingBox = "bbox"
        
        static let PageOfResults = "page"
        static let PhotosPerPage = "per_page"
    }
    
    // MARK: Flickr Parameter Values
    
    struct FlickrParameterValues {
        static let SearchMethod = "flickr.photos.search"
        static let APIKey = "f9af1e24839530952008b73e6a329080"
        static let UseSafeSearch = "1"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1"
        static let ExtrasH = "url_h,date_taken"
        static let ExtrasM = "url_m,date_taken"
        
        static let PhotosPerPage = "120"
    }
    
    // MARK: Flickr Response Keys
    
    struct FlickrResponseKeys {
        static let BoundingBox = "bbox"
        static let Status = "stat"
        static let Photos_Dic = "photos"
        static let Photo_Arr = "photo"
        static let ExtrasM = "url_m"
        static let ExtrasH = "url_h"
        static let PhotoID = "id"
        static let DateTaken = "datetaken"
        
        static let CurrentPage = "page"
        static let NumOfPages = "pages"
        static let PhotosPerPage = "perpage"
        static let TotalPhotos = "total"
    }
    
    // MARK: Flickr Response Values
    
    struct FlickrResponseValues {
        static let OKStatus = "ok"
    }
}
