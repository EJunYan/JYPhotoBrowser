//
//  MainAssetGridViewController.swift
//  JYPhotoBrowser
//
//  Created by eruYan on 2019/1/2.
//  Copyright © 2019 eruYan. All rights reserved.
//

import UIKit
import Foundation
import Photos
import PhotosUI

extension UICollectionView {
    
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
    
}

public protocol SelectAssetDelegate {
    
    func setThumbnailImage(size: CGSize)
    
    func selectAsset(thumbnailImage images: [UIImage], assets: [PHAsset])
}

open class MainAssetGridViewController: UIViewController,
UICollectionViewDelegate,UICollectionViewDataSource
{
    
    open var fetchResult: PHFetchResult<PHAsset>!
    open var assetCollection: PHAssetCollection!
    
    fileprivate var availableWidth: CGFloat = 0
    
    fileprivate lazy var collectionViewFlowLayout: UICollectionViewFlowLayout = {
       let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 80.0, height: 80.0)
        layout.minimumInteritemSpacing = 1.0
        layout.minimumLineSpacing = 1.0
        return layout
    }()
    
    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var thumbnailSize: CGSize!
    fileprivate var previousPreheatRect = CGRect.zero
    
    fileprivate var collectionView: UICollectionView!
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        // CollectionView Init
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        var bounds: CGRect!
        
        if #available(iOS 11.0, *) {
            bounds = view.bounds.inset(by: view.safeAreaInsets)
        } else {
            // Fallback on earlier versions
            bounds = view.bounds
        }
        
        self.collectionView = UICollectionView(frame: bounds, collectionViewLayout: collectionViewFlowLayout)
        self.collectionView.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.collectionView.register(GridViewCell.self, forCellWithReuseIdentifier: "GridViewCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        self.view.addSubview(self.collectionView)

        resetCachedAssets()
        PHPhotoLibrary.shared().register(self)
        
        // Reaching this point without a segue means that this AssetGridViewController
        // became visible at app launch. As such, match the behavior of the segue from
        // the default "All Photos" view.
        if fetchResult == nil { // 默认获取所有
            let allPhotosOptions = PHFetchOptions()
            allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
        }
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        var width: CGFloat!
        
        if #available(iOS 11.0, *) {
            width = view.bounds.inset(by: view.safeAreaInsets).width
        } else {
            // Fallback on earlier versions
            width = view.bounds.width
        }
        // Adjust the item size if the available width has changed.
        if availableWidth != width {
            availableWidth = width
            
            let columnCount = (availableWidth / 80.0).rounded(.towardZero)
            let itemLength = (availableWidth - columnCount - 1) / columnCount
            collectionViewFlowLayout.itemSize = CGSize(width: itemLength, height: itemLength)
//            self.collectionView.reloadData()
            self.collectionView.setCollectionViewLayout(collectionViewFlowLayout, animated: false)
        }
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Determine the size of the thumbnails to request from the PHCachingImageManager.
        let scale:CGFloat = UIScreen.main.scale
        let cellSize = collectionViewFlowLayout.itemSize
        thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
        
        // Add a button to the navigation bar if the asset collection supports adding content.
        // TODO: 可以设置为拍照
//        if assetCollection == nil || assetCollection.canPerform(.addContent) {
//            navigationItem.rightBarButtonItem = addButtonItem
//        } else {
//            navigationItem.rightBarButtonItem = nil
//        }
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCachedAssets()
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        guard let destination = segue.destination as? AssetViewController else { fatalError("Unexpected view controller for segue") }
//        guard let collectionViewCell = sender as? UICollectionViewCell else { fatalError("Unexpected sender for segue") }
//
//        let indexPath = collectionView.indexPath(for: collectionViewCell)!
//        destination.asset = fetchResult.object(at: indexPath.item)
//        destination.assetCollection = assetCollection
//    }
    
    // MARK: UICollectionView
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.count
    }
    
    /// - Tag: PopulateCell
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = fetchResult.object(at: indexPath.item)
        // Dequeue a GridViewCell.
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridViewCell", for: indexPath) as? GridViewCell
            else { fatalError("Unexpected cell in collection view") }
        
        // Add a badge to the cell if the PHAsset represents a Live Photo.
        if #available(iOS 9.1, *) {
            if asset.mediaSubtypes.contains(.photoLive) {
                cell.livePhotoBadgeImage = PHLivePhotoView.livePhotoBadgeImage(options: .overContent)
            }
        } else {
            // Fallback on earlier versions
        }
        
        if asset.mediaType == .video {
            debugPrint("视频时长", asset.duration)
            cell.videoBadgeImage = #imageLiteral(resourceName: "iosVideocamOutline")
            cell.duration = asset.duration
        }
        
        // Request an image for the asset from the PHCachingImageManager.
        cell.representedAssetIdentifier = asset.localIdentifier
        imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
            // UIKit may have recycled this cell by the handler's activation time.
            // Set the cell's thumbnail image only if it's still showing the same asset.
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.thumbnailImage = image
            }
        })
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = BrowserAssetViewController()
        vc.currentIndex = indexPath.item
        vc.fetchResult = self.fetchResult
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: UIScrollView
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
    // MARK: Asset Caching
    
    fileprivate func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    /// - Tag: UpdateAssets
    fileprivate func updateCachedAssets() {
        // Update only if the view is visible.
        guard isViewLoaded && view.window != nil else { return }
        
        // The window you prepare ahead of time is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        // Compute the assets to start and stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        
        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        // Store the computed rectangle for future comparison.
        previousPreheatRect = preheatRect
    }
    
    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
    
    // MARK: UI Actions
    /// - Tag: AddAsset
    @IBAction func addAsset(_ sender: AnyObject?) {
        assert(false)
        // Create a dummy image of a random solid color and random orientation.
        
        let size = (arc4random_uniform(2) == 0) ?
            CGSize(width: 400, height: 300) :
            CGSize(width: 300, height: 400)
        
        if #available(iOS 10.0, *) {
            let renderer = UIGraphicsImageRenderer(size: size)
            
            let image = renderer.image { context in
                UIColor(hue: CGFloat(arc4random_uniform(100)) / 100,
                        saturation: 1, brightness: 1, alpha: 1).setFill()
                context.fill(context.format.bounds)
            }
            // MARK: 把图片保存到相册
            // Add the asset to the photo library.
            PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                creationRequest.creationDate = Date()
                //            creationRequest.location
                if let assetCollection = self.assetCollection {
                    let addAssetRequest = PHAssetCollectionChangeRequest(for: assetCollection)
                    addAssetRequest?.addAssets([creationRequest.placeholderForCreatedAsset!] as NSArray)
                }
            }, completionHandler: {success, error in
                if !success { print("Error creating the asset: \(String(describing: error))") }
            })
        } else {
            // Fallback on earlier versions
        }
        
    }
}


// MARK: PHPhotoLibraryChangeObserver
extension MainAssetGridViewController: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        guard let changes = changeInstance.changeDetails(for: fetchResult)
            else { return }
        
        // Change notifications may originate from a background queue.
        // As such, re-dispatch execution to the main queue before acting
        // on the change, so you can update the UI.
        DispatchQueue.main.sync {
            // Hang on to the new fetch result.
            fetchResult = changes.fetchResultAfterChanges
            // If we have incremental changes, animate them in the collection view.
            if changes.hasIncrementalChanges {
                guard let collectionView = self.collectionView else { fatalError() }
                // Handle removals, insertions, and moves in a batch update.
                collectionView.performBatchUpdates({
                    if let removed = changes.removedIndexes, !removed.isEmpty {
                        collectionView.deleteItems(at: removed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let inserted = changes.insertedIndexes, !inserted.isEmpty {
                        collectionView.insertItems(at: inserted.map({ IndexPath(item: $0, section: 0) }))
                    }
                    changes.enumerateMoves { fromIndex, toIndex in
                        collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                to: IndexPath(item: toIndex, section: 0))
                    }
                })
                // We are reloading items after the batch update since `PHFetchResultChangeDetails.changedIndexes` refers to
                // items in the *after* state and not the *before* state as expected by `performBatchUpdates(_:completion:)`.
                if let changed = changes.changedIndexes, !changed.isEmpty {
                    collectionView.reloadItems(at: changed.map({ IndexPath(item: $0, section: 0) }))
                }
            } else {
                // Reload the collection view if incremental changes are not available.
                collectionView.reloadData()
            }
            resetCachedAssets()
        }
    }
}
