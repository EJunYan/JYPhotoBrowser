//
//  GridViewCell.swift
//  JYPhotoBrowser
//
//  Created by eruYan on 2019/1/2.
//  Copyright © 2019 eruYan. All rights reserved.
//

import UIKit
import Photos

class GridViewCell: UICollectionViewCell {
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.frame = self.bounds
        return imageView
    }()
    
    var representedAssetIdentifier: String!
    
    private lazy var livePhotoBadgeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        return imageView
    }()
    
    private lazy var checkButton:UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        let size = CGSize(width: 23, height: 23)
        let x = self.bounds.width - size.width - 2
        button.setImage(#imageLiteral(resourceName: "iosCheckmarkOutline"), for: .normal)
        button.frame = CGRect(x: x, y: 2, width: size.width, height: size.height)
        return button
    }()
    
    private lazy var videoBadgeImageView: UIImageView = {
        let imageView = UIImageView()
        let y: CGFloat = self.bounds.height - 20
        imageView.frame = CGRect(x: 10, y: y, width: 18.5, height: 11)
        return imageView
    }()
    
    private lazy var videoDurationLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 10)
        let width: CGFloat = self.bounds.width
        let height: CGFloat = 11.5
        let y = self.bounds.height - height - 10.0
        label.frame = CGRect(x: 0, y: y, width: width, height: height)
        return label
    }()
    
    var thumbnailImage: UIImage! {
        didSet {
            imageView.image = thumbnailImage
        }
    }
    var livePhotoBadgeImage: UIImage! {
        didSet {
            livePhotoBadgeImageView.image = livePhotoBadgeImage
        }
    }
    
    var videoBadgeImage: UIImage! {
        didSet {
            videoBadgeImageView.image = videoBadgeImage
        }
    }
    
    var duration: Double! {
        didSet {
            let id = lround(duration)
            let min = id / 60
            let sec = id % 50
            let text = String.init(format: "%02d:%02d", min,sec)
            self.videoDurationLabel.text = text
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(imageView)
        addSubview(livePhotoBadgeImageView)
        addSubview(checkButton)
        addSubview(videoBadgeImageView)
        addSubview(videoDurationLabel)
        
        imageView.image = nil
        livePhotoBadgeImageView.image = nil
        videoBadgeImageView.image = nil
        videoDurationLabel.text = nil
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
