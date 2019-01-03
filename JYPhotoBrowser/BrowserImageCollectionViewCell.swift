//
//  BrowserImageCollectionViewCell.swift
//  JYPhotoBrowser
//
//  Created by eruYan on 2019/1/3.
//  Copyright © 2019 eruYan. All rights reserved.
//

import UIKit

class BrowserImageCollectionViewCell: UICollectionViewCell {
    
    var representedAssetIdentifier: String!
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.frame = self.bounds
        scrollView.isScrollEnabled = true
        scrollView.maximumZoomScale = UIScreen.main.scale
        return scrollView
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.frame = self.bounds
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    var thumbnailImage: UIImage! {
        didSet {
            imageView.image = thumbnailImage
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        scrollView.delegate = self
        addSubview(scrollView)
        scrollView.contentSize = imageView.frame.size
        
        scrollView.addSubview(imageView)
        imageView.image = nil
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension BrowserImageCollectionViewCell: UIScrollViewDelegate {
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        var centerx = scrollView.center.x
        var centery = scrollView.center.y
        centerx = scrollView.contentSize.width > scrollView.frame.size.width ? scrollView.contentSize.width/2 : centerx;
        centery = scrollView.contentSize.height > scrollView.frame.size.height ? scrollView.contentSize.height/2 : centery;
        imageView.center = CGPoint(x: centerx, y: centery)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

