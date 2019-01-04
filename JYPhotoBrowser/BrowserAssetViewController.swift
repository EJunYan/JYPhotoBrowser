//
//  BrowserAssetViewController.swift
//  JYPhotoBrowser
//
//  Created by eruYan on 2019/1/2.
//  Copyright © 2019 eruYan. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

open class BrowserAssetViewController: UIViewController,
    UICollectionViewDelegate,UICollectionViewDataSource
{
    
    private let kItemMargin:CGFloat = 20.0
    
    private var isFirstDisplayCell = true
    private var displayCellIndexPath: IndexPath!
    private var willDisplayCellIndexPath: IndexPath!
    
    open var currentIndex: Int = 0
    
    private var safeAreaSize: CGSize {
        
        var width: CGFloat!
        var height: CGFloat!
        
        if #available(iOS 11.0, *) {
//            width = view.bounds.inset(by: view.safeAreaInsets).width
//            height = view.bounds.inset(by: view.safeAreaInsets).height
            width = view.bounds.width
            height = view.bounds.height
        } else {
            // Fallback on earlier versions
            width = view.bounds.width
            height = view.bounds.height
        }
        return CGSize(width: width, height: height)
    }
    
    private var targetSize: CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: safeAreaSize.width * scale, height: safeAreaSize.height * scale)
    }
    
    // 相册集结果
    open var fetchResult: PHFetchResult<PHAsset>!

    private var availableWidth: CGFloat!
    
    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: UIProgressView.Style.default)
        progressView.frame.size = CGSize(width: UIScreen.main.bounds.width, height: 1.0)
        progressView.isHidden = true
        return progressView
    }()
    
    
    
    lazy var collectionViewFlowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0.0
        layout.minimumLineSpacing = kItemMargin
        layout.scrollDirection = .horizontal
        return layout
    }()
    
    fileprivate var playerLayer: AVPlayerLayer?
    fileprivate var isPlayingHint = false
    
    fileprivate lazy var formatIdentifier = Bundle.main.bundleIdentifier!
    fileprivate let formatVersion = "1.0"
    fileprivate lazy var ciContext = CIContext()
    
    fileprivate let imageManager = PHCachingImageManager()

    fileprivate var previousPreheatRect = CGRect.zero
    
    fileprivate var collectionView: UICollectionView!
    
    func collectionViewInit() {
        if collectionView == nil {
            
            // Uncomment the following line to preserve selection between presentations
            // self.clearsSelectionOnViewWillAppear = false
            self.collectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: collectionViewFlowLayout)
            self.collectionView.isPagingEnabled = true
            self.collectionView.scrollsToTop = false
            self.collectionView.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            
            self.collectionView.register(BrowserImageCollectionViewCell.self, forCellWithReuseIdentifier: "BrowserImageCollectionViewCell")
            self.collectionView.register(BrowserVideoCollectionViewCell.self, forCellWithReuseIdentifier: "BrowserVideoCollectionViewCell")
            
            self.collectionView.showsVerticalScrollIndicator = false
            self.collectionView.showsHorizontalScrollIndicator = false
            
            self.collectionView.delegate = self
            self.collectionView.dataSource = self
            
            self.view.addSubview(self.collectionView)
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.isFirstDisplayCell = true
        
        collectionViewInit()
        
        let y = self.navigationController?.navigationBar.bounds.height ?? 1.0 - 1.0
        progressView.frame = CGRect(origin: CGPoint(x: 0, y: y), size: progressView.frame.size)
        self.navigationController?.navigationBar.addSubview(progressView)
        
        
        // 数据初始化
        resetCachedAssets()
        PHPhotoLibrary.shared().register(self)
        
        if fetchResult == nil { // 默认获取所有
            let allPhotosOptions = PHFetchOptions()
            allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
        }
    }
    
    open override var prefersStatusBarHidden: Bool {
        return false
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
 
        // Adjust the item size if the available width has changed.
        if availableWidth != safeAreaSize.width {
            availableWidth = safeAreaSize.width
            
            collectionViewFlowLayout.minimumLineSpacing = kItemMargin
            collectionViewFlowLayout.sectionInset = UIEdgeInsets(top: 0, left: kItemMargin / 2.0, bottom: 0, right: kItemMargin / 2.0)
            collectionViewFlowLayout.itemSize = safeAreaSize
            self.collectionView.setCollectionViewLayout(collectionViewFlowLayout, animated: false)
            
            collectionView.frame = CGRect(x: -kItemMargin / 2.0, y: 0, width: safeAreaSize.width + kItemMargin, height: safeAreaSize.height)
            
            collectionView.contentOffset = CGPoint(x: (kItemMargin + safeAreaSize.width) * CGFloat(currentIndex), y: 0)
            
        }
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // collectionView top
        self.navigationController?.hidesBarsOnTap = true
        if #available(iOS 11.0, *) {
            self.collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
            self.automaticallyAdjustsScrollViewInsets = false
        }
        
        collectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: UICollectionView.ScrollPosition.right, animated: false)
//        collectionView.contentOffset = CGPoint(x: (kItemMargin + safeAreaSize.width) * CGFloat(currentIndex), y: 0)
        
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCachedAssets()
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.hidesBarsOnTap = false
        
    }
    
   
    // MARK: UICollectionView
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.count
    }
    /// - Tag: PopulateCell
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        debugPrint(#function)
        
        progressView.isHidden = false
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.progressHandler = { progress, _, _, _ in
//             The handler may originate on a background queue, so
//             re-dispatch to the main queue for UI work.
            DispatchQueue.main.sync {
                self.progressView.progress = Float(progress)
            }
        }
        
        let asset = fetchResult.object(at: indexPath.item)
        let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        
        // TODO: 计算合适的 targetSize 大小
        debugPrint("pixelSize",asset.mediaType ,targetSize)
        
        switch asset.mediaType {
            
        case .image:
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BrowserImageCollectionViewCell", for: indexPath) as? BrowserImageCollectionViewCell else { fatalError("Unexpected cell in collection view") }
            
            cell.representedAssetIdentifier = asset.localIdentifier
            
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { (image, _) in
                self.progressView.isHidden = true
                if cell.representedAssetIdentifier == asset.localIdentifier {
                    cell.thumbnailImage = image
                }
            }
            return cell
            
        case .video:
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BrowserVideoCollectionViewCell", for: indexPath) as? BrowserVideoCollectionViewCell else { fatalError("Unexpected cell in collection view") }
            
            cell.representedAssetIdentifier = asset.localIdentifier
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { (image, _) in
                self.progressView.isHidden = true
                if cell.representedAssetIdentifier == asset.localIdentifier {
                    cell.thumbnailImage = image
                }
            }
            
            if isFirstDisplayCell {
                playVideo(cell: cell, forItemAt: asset)
            }
            
            return cell
            
        default:
            assert(false)
        }
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        debugPrint(#function, indexPath)
        if isFirstDisplayCell {
            isFirstDisplayCell = false
            displayCellIndexPath = indexPath
            playAsset(forItemAt: displayCellIndexPath)
        } else {
            stopAsset(forItemAt: indexPath)
            willDisplayCellIndexPath = indexPath
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        debugPrint(#function, indexPath)
        if indexPath == willDisplayCellIndexPath {
            playAsset(forItemAt: displayCellIndexPath)
        } else {
            displayCellIndexPath = willDisplayCellIndexPath
            playAsset(forItemAt: displayCellIndexPath)
        }

    }
    
    func stopAsset(forItemAt indexPath: IndexPath) {
        if playerLayer != nil {
            playerLayer?.player?.pause()
            playerLayer?.removeFromSuperlayer()
            playerLayer = nil
        }
    }
    
    func playVideo(cell: UICollectionViewCell, forItemAt asset: PHAsset) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic
        options.progressHandler = { progress, _, _, _ in
            // The handler may originate on a background queue, so
            // re-dispatch to the main queue for UI work.
            DispatchQueue.main.sync {
                self.progressView.progress = Float(progress)
            }
        }
        
        // Request an AVPlayerItem for the displayed PHAsset.
        // Then configure a layer for playing it.
        imageManager.requestPlayerItem(forVideo: asset, options: options, resultHandler: { playerItem, info in
            DispatchQueue.main.async {
                guard self.playerLayer == nil else { return }
                
                // Create an AVPlayer and AVPlayerLayer with the AVPlayerItem.
                let player = AVPlayer(playerItem: playerItem)
                let playerLayer = AVPlayerLayer(player: player)
                
                // Configure the AVPlayerLayer and add it to the view.
                playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                playerLayer.frame = self.view.layer.bounds
                
//                self.view.layer.addSublayer(playerLayer)
                
                player.play()
                cell.layer.addSublayer(playerLayer)
                // Cache the player layer by reference, so you can remove it later.
                self.playerLayer = playerLayer
            } // DispatchQueue.main.sync
        })// PHImageManager.default()
    }
    
    func playAsset(forItemAt indexPath: IndexPath) {
        
        stopAsset(forItemAt: indexPath)
        
        currentIndex = indexPath.item
        debugPrint("当前 currentIndex : ", currentIndex)
        let asset = self.fetchResult.object(at: indexPath.item)
        switch asset.mediaType {
        case .video:
            guard let cell = collectionView.cellForItem(at: IndexPath.init(row: currentIndex, section: 0)) as? BrowserVideoCollectionViewCell,cell.representedAssetIdentifier == asset.localIdentifier else {
                return
            }
            playVideo(cell: cell, forItemAt: asset)
        default:
            break
        }
        
    }
    

    
    // MARK: UIScrollView
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
        // 滑动暂停一切播放
//        guard scrollView == self.collectionView else {
//            return
//        }
//        let offset = self.collectionView.contentOffset;
//        let page = offset.x / ( UIScreen.main.bounds.width + kItemMargin);
//        if (ceilf(Float(page)) >= Float(self.fetchResult.count)) {
//            currentIndex = Int(page)
//            return
//        }
//        let asset = self.fetchResult.object(at: currentIndex)
//        switch asset.mediaType {
//        case .image:
//
//            guard let cell = collectionView.cellForItem(at: IndexPath.init(row: currentIndex, section: 0)) as? BrowserImageCollectionViewCell else {
//                return
//            }
//
//            break
//        case .video:
//            guard let cell = collectionView.cellForItem(at: IndexPath.init(row: currentIndex, section: 0)) as? BrowserVideoCollectionViewCell else {
//                return
//            }
//            break
//        default:
//            assert(false)
//        }

    }
//
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

//        guard scrollView == self.collectionView else {
//            return
//        }
//
//        let asset = self.fetchResult.object(at: currentIndex)
//        switch asset.mediaType {
//        case .image:
//
//            guard let cell = collectionView.cellForItem(at: IndexPath.init(row: currentIndex, section: 0)) as? BrowserImageCollectionViewCell else {
//                return
//            }
//
//            break
//        case .video:
//            guard let cell = collectionView.cellForItem(at: IndexPath.init(row: currentIndex, section: 0)) as? BrowserVideoCollectionViewCell else {
//                return
//            }
//            break
//        default:
//            assert(false)
//        }
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
        let preheatRect = visibleRect.insetBy(dx: -1.5 * visibleRect.height, dy: 0)
        
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
                                        targetSize: self.targetSize, contentMode: .aspectFit, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: self.targetSize, contentMode: .aspectFit, options: nil)
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

}


// MARK: PHPhotoLibraryChangeObserver
extension BrowserAssetViewController: PHPhotoLibraryChangeObserver {
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
