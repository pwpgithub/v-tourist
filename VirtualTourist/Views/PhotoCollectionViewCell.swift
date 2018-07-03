//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Ping Wu on 3/6/18.
//  Copyright © 2018 SHDR. All rights reserved.
//

import UIKit

// MARK: - PhotoCollectionViewCell: UICollectionViewCell
class PhotoCollectionViewCell: UICollectionViewCell {
    
    // MARK: Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var opaqueView: UIView!
    
    // MARK: Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()

        opaqueView.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        opaqueView.isHidden = self.isSelected == false
        update(with: nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
       
        opaqueView.isHidden = true
        update(with: nil)
    }
    
    // MARK:
    
    func update(with image: UIImage?) {
        
        if let imageToDisplay = image {
            spinner.stopAnimating()
            imageView.image = imageToDisplay
        } else {
            spinner.startAnimating()
            imageView.image = nil
        }
    }
}
