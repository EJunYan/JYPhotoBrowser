//
//  BrowserVideoCollectionViewCell.swift
//  JYPhotoBrowser
//
//  Created by eruYan on 2019/1/3.
//  Copyright © 2019 eruYan. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class BrowserVideoCollectionViewCell: UICollectionViewCell {
    
    var representedAssetIdentifier: String!
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.frame = self.bounds
        return imageView
    }()
    
    private lazy var videoBadgeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        imageView.image = #imageLiteral(resourceName: "Icon-elusive-play-circled")
        return imageView
    }()
    
    var thumbnailImage: UIImage! {
        didSet {
            imageView.image = thumbnailImage
        }
    }
    
    var videoBadgeImage: UIImage! {
        didSet {
            videoBadgeImageView.image = videoBadgeImage
        }
    }
    
    fileprivate var playerLayer: AVPlayerLayer!
    fileprivate var isPlayingHint = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        videoBadgeImageView.center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
        addSubview(videoBadgeImageView)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
