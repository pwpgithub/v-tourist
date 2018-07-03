//
//  PhotoDataSource.swift
//  VirtualTourist
//
//  Created by Ping Wu on 3/6/18.
//  Copyright © 2018 SHDR. All rights reserved.
//

import UIKit

// MARK: - PhotoDataSource: NSObject, UICollectionViewDataSource
class PhotoDataSource: NSObject, UICollectionViewDataSource {
    
    // MARK: Properties
    var photos: [Photo] = []
    
    // MARK: DataSource    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let identifier = "PhotoCollectionViewCell"
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! PhotoCollectionViewCell
        
        return cell
    }
}
