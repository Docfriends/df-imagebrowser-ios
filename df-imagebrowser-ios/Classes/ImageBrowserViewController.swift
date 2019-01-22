//
//  ImageBrowserViewController
//

import UIKit

public protocol ImageBrowserDelegate: class {
    func imageBrowserDismiss(_ viewController: UIViewController)
    func imageBrowserShareError(_ viewController: UIViewController, asset: ImageBrowserAsset)
    func imageBrowserError(_ viewController: UIViewController, asset: ImageBrowserAsset)
}

public extension ImageBrowserDelegate {
    func imageBrowserDismiss(_ viewController: UIViewController) {
        if let viewController = viewController.navigationController?.viewControllers.first as? ImageBrowserViewController {
            viewController.dismiss(animated: true, completion: nil)
        } else {
            viewController.navigationController?.popViewController(animated: true)
        }
    }
    func imageBrowserShare(_ error: Error?, asset: ImageBrowserAsset) { }
    func imageBrowser(_ error: Error?, asset: ImageBrowserAsset) { }
}

open class ImageBrowserViewController: UIViewController {
    public weak var delegate: ImageBrowserDelegate?
    
    public var barTintColor = UIColor.white {
        willSet {
            self.navigationController?.navigationBar.barTintColor = newValue
            self.navigationController?.navigationBar.backgroundColor = newValue
        }
    }
    
    public var tintColor = UIColor(red: 53/255, green: 123/255, blue: 246/255, alpha: 1) {
        willSet {
            let squareButtonItem = UIBarButtonItem(image: ImageBrowserSquareView.imageView(newValue), style: .plain, target: self, action: #selector(self.moreTap(_:)))
            self.navigationItem.setRightBarButton(squareButtonItem, animated: true)
            self.navigationItem.leftBarButtonItem?.tintColor = newValue
            self.navigationItem.rightBarButtonItem?.tintColor = newValue
            self.navigationItem.backBarButtonItem?.tintColor = newValue
            self.navigationController?.navigationBar.tintColor = newValue
            self.titleButton.tintColor = newValue
            self.titleButton.setImage(ImageBrowserBottomArrowView.imageView(newValue), for: .normal)
        }
    }
    
    // more
    
    public var moreCellColor = UIColor(white: 210/255, alpha: 1) {
        willSet {
            ImageBrowserZoomCell.moreCellColor = newValue
        }
    }
    
    public var moreErrorColor = UIColor.black {
        willSet {
            ImageBrowserZoomCell.moreErrorColor = newValue
        }
    }
    
    public var moreProgressTextColor = UIColor.black {
        willSet {
            ImageBrowserZoomCell.moreProgressTextColor = newValue
        }
    }
    
    public var moreProgressColor = UIColor.black {
        willSet {
            ImageBrowserZoomCell.moreProgressColor = newValue
        }
    }
    
    public var moreProgressTintColor = UIColor(red: 15/255, green: 148/255, blue: 252/255, alpha: 1) {
        willSet {
            ImageBrowserZoomCell.moreProgressTintColor = newValue
        }
    }
    
    public var moreProgressBackgroundColor = UIColor(white: 210/255, alpha: 1) {
        willSet {
            ImageBrowserZoomCell.moreProgressBackgroundColor = newValue
        }
    }
    
    // zoom
    
    public var zoomCellColor = UIColor.black {
        willSet {
            ImageBrowserZoomCell.zoomCellColor = newValue
        }
    }
    
    public var zoomErrorColor = UIColor.white {
        willSet {
            ImageBrowserZoomCell.zoomErrorColor = newValue
        }
    }
    
    public var zoomProgressTextColor = UIColor.white {
        willSet {
            ImageBrowserZoomCell.zoomProgressTextColor = newValue
        }
    }
    
    public var zoomProgressColor = UIColor(white: 206/255, alpha: 1) {
        willSet {
            ImageBrowserZoomCell.zoomProgressColor = newValue
        }
    }
    
    public var zoomProgressTintColor = UIColor(red: 15/255, green: 148/255, blue: 252/255, alpha: 1) {
        willSet {
            ImageBrowserZoomCell.zoomProgressTintColor = newValue
        }
    }
    
    public var zoomProgressBackgroundColor = UIColor.black {
        willSet {
            ImageBrowserZoomCell.zoomProgressBackgroundColor = newValue
        }
    }
    
    
    public var isMoreButtonHidden: Bool = false {
        willSet {
            if newValue {
                self.navigationItem.rightBarButtonItem = nil
            } else {
                let squareButtonItem = UIBarButtonItem(image: ImageBrowserSquareView.imageView(self.tintColor), style: .plain, target: self, action: #selector(self.moreTap(_:)))
                self.navigationItem.rightBarButtonItem = squareButtonItem
            }
        }
    }
    
    public var zoomBackgroundColor: UIColor = .black {
        willSet {
            self.view.backgroundColor = newValue
        }
    }
    
    public var moreBackgroundColor: UIColor = .black
    
    private var imageAssets = [ImageBrowserAsset]()
    
    private lazy var collectionView: ImageBrowserCollectionView = {
        let topConstant: CGFloat = (self.navigationController?.navigationBar.frame.height ?? 0) + UIApplication.shared.statusBarFrame.height
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let frame = CGRect(x: 0, y: topConstant, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - topConstant)
        let collectionView = ImageBrowserCollectionView(frame: frame, collectionViewLayout: layout)
        self.view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.edgesConstraint(subView: collectionView)
        return collectionView
    }()
    
    private var isInteractivePopGestureRecognizerEnabled: Bool?
    
    private lazy var titleButton: UIButton = {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: self.navigationController?.navigationBar.frame.height ?? 44)
        button.semanticContentAttribute = .forceRightToLeft
        button.setImage(ImageBrowserBottomArrowView.imageView(self.tintColor), for: .normal)
        button.tintColor = self.tintColor
        button.imageEdgeInsets.right -= 10
        button.contentEdgeInsets.right += 10
        return button
    }()
    
    private var isMore = false
    private var index = 0
    
    public init(_ imageAssets: [ImageBrowserAsset], index: Int = 0) {
        super.init(nibName: nil, bundle: nil)
        
        self.imageAssets = imageAssets
        self.index = index
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = self.zoomBackgroundColor
        
        self.navigationController?.navigationBar.barTintColor = self.barTintColor
        self.navigationController?.navigationBar.backgroundColor = self.barTintColor
        
        self.navigationItem.backBarButtonItem?.tintColor = self.tintColor
        self.navigationItem.leftBarButtonItem?.tintColor = self.tintColor
        self.navigationItem.rightBarButtonItem?.tintColor = self.tintColor
        self.navigationController?.navigationBar.tintColor = self.tintColor
        
        DispatchQueue.main.async {
            self.navigationController?.navigationBar.tintColor = self.tintColor
            
            if !self.isMoreButtonHidden {
                let squareButtonItem = UIBarButtonItem(image: ImageBrowserSquareView.imageView(self.tintColor), style: .plain, target: self, action: #selector(self.moreTap(_:)))
                self.navigationItem.rightBarButtonItem = squareButtonItem
            }
        }
        
        ImageBrowserZoomCell.zoomCellColor = self.zoomCellColor
        ImageBrowserZoomCell.zoomErrorColor = self.zoomErrorColor
        ImageBrowserZoomCell.zoomProgressTextColor = self.zoomProgressTextColor
        ImageBrowserZoomCell.zoomProgressColor = self.zoomProgressColor
        ImageBrowserZoomCell.zoomProgressTintColor = self.zoomProgressTintColor
        ImageBrowserZoomCell.zoomProgressBackgroundColor = self.zoomProgressBackgroundColor
        
        ImageBrowserZoomCell.moreCellColor = self.moreCellColor
        ImageBrowserZoomCell.moreErrorColor = self.moreErrorColor
        ImageBrowserZoomCell.moreProgressTextColor = self.moreProgressTextColor
        ImageBrowserZoomCell.moreProgressColor = self.moreProgressColor
        ImageBrowserZoomCell.moreProgressTintColor = self.moreProgressTintColor
        ImageBrowserZoomCell.moreProgressBackgroundColor = self.moreProgressBackgroundColor
        
        self.collectionView.register(ImageBrowserZoomCell.self, forCellWithReuseIdentifier: ImageBrowserZoomCell.identifier)
        if #available(iOS 11.0, *) {
            self.collectionView.contentInsetAdjustmentBehavior = .never
        }
        self.collectionView.backgroundColor = .clear
        self.collectionView.contentInset = .zero
        self.collectionView.isPagingEnabled = true
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.reloadData()
        self.collectionView.layoutIfNeeded()
        
        self.navigationItem.titleView = self.titleButton
        self.titleButton.addTarget(self, action: #selector(self.shareTap(_:)), for: .touchUpInside)
        self.titleButton.setTitle("\(self.collectionView.currentIndex+1) / \(self.imageAssets.count)", for: .normal)
        self.titleButton.sizeToFit()
        
        self.collectionView.scrollToItem(at: IndexPath(row: self.index, section: 0), at: .centeredHorizontally, animated: false)
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.imageAssets.count > 1 {
            self.isInteractivePopGestureRecognizerEnabled = self.navigationController?.interactivePopGestureRecognizer?.isEnabled
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }
        self.navigationController?.setNeedsStatusBarAppearanceUpdate()
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.imageAssets.count > 1 {
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = self.isInteractivePopGestureRecognizerEnabled ?? true
        }
    }
    
    @objc func shareTap(_ sender: UIButton) {
        let index = self.collectionView.currentIndex
        if index >= self.imageAssets.count { return }
        guard let image = self.imageAssets[index].image else {
            self.delegate?.imageBrowserShareError(self, asset: self.imageAssets[index])
            return
        }
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @objc func moreTap(_ sender: UIBarButtonItem) {
        self.isMore = true
        if #available(iOS 11.0, *) {
            self.collectionView.contentInsetAdjustmentBehavior = .always
        }
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = self.isInteractivePopGestureRecognizerEnabled ?? true
        self.titleButton.setTitle("", for: .normal)
        self.titleButton.setImage(nil, for: .normal)
        self.titleButton.sizeToFit()
        self.navigationItem.rightBarButtonItem = nil
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        self.collectionView.collectionViewLayout = layout
        self.collectionView.isPagingEnabled = false
        self.collectionView.reloadData()
        self.view.backgroundColor = self.moreBackgroundColor
    }
    
    @objc public func backTap(_ sender: UIButton) {
        if let delegate = self.delegate {
            delegate.imageBrowserDismiss(self)
        } else {
            if let viewController = self.navigationController?.viewControllers.first as? ImageBrowserViewController {
                viewController.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}

// MARK: UICollectionViewDelegate
extension ImageBrowserViewController: UICollectionViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !self.isMore else { return }
        if let collectionView = scrollView as? ImageBrowserCollectionView {
            collectionView.setCurrentIndexListCount(self.imageAssets.count)
            self.titleButton.setTitle("\(collectionView.currentIndex+1) / \(self.imageAssets.count)", for: .normal)
            self.titleButton.sizeToFit()
        }
    }
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard self.isMore else { return }
        self.isMore = false
        if #available(iOS 11.0, *) {
            self.collectionView.contentInsetAdjustmentBehavior = .never
        }
        self.isInteractivePopGestureRecognizerEnabled = self.navigationController?.interactivePopGestureRecognizer?.isEnabled
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        let squareButtonItem = UIBarButtonItem(image: ImageBrowserSquareView.imageView(self.tintColor), style: .plain, target: self, action: #selector(self.moreTap(_:)))
        self.navigationItem.rightBarButtonItem = squareButtonItem
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        self.collectionView.collectionViewLayout = layout
        self.collectionView.isPagingEnabled = true
        self.collectionView.reloadData()
        self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        self.collectionView.setCurrentIndexListCount(self.imageAssets.count)
        self.titleButton.setTitle("\(indexPath.row+1) / \(self.imageAssets.count)", for: .normal)
        self.titleButton.sizeToFit()
        self.view.backgroundColor = self.zoomBackgroundColor
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            self.titleButton.setImage(ImageBrowserBottomArrowView.imageView(self.tintColor), for: .normal)
            self.titleButton.sizeToFit()
        }
    }
}

// MARK: UICollectionViewDataSource
extension ImageBrowserViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.imageAssets.count
    }
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell  as? ImageBrowserZoomCell else { return }
        let indexPath = indexPath
        let index = indexPath.row
        let item = self.imageAssets[index]
        if item.type == .wait {
            self.imageAssets[index].type = .download(progress: 0)
            cell.imageAsset = self.imageAssets[index]
            ImageBrowserDownload.load(item.url, progress: { [weak self] (progress) in
                self?.imageAssets[index].type = .download(progress: progress)
                if let cell = self?.collectionView.cellForItem(at: indexPath) as? ImageBrowserZoomCell {
                    cell.imageAsset = self?.imageAssets[index]
                }
            }) { [weak self] (error, image) in
                if error == nil, let image = image {
                    self?.imageAssets[index].image = image
                    self?.imageAssets[index].type = .success
                } else {
                    self?.imageAssets[index].type = .error(error: error)
                }
                if let cell = self?.collectionView.cellForItem(at: indexPath) as? ImageBrowserZoomCell {
                    cell.imageAsset = self?.imageAssets[index]
                }
            }
        }
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageBrowserZoomCell.identifier, for: indexPath) as? ImageBrowserZoomCell else {
            return UICollectionViewCell()
        }
        let indexPath = indexPath
        let index = indexPath.row
        let item = self.imageAssets[index]
        cell.isMore = self.isMore
        if item.type == .success {
            cell.imageAsset = item
        } else if item.type == .error(error: nil) {
            self.delegate?.imageBrowserError(self, asset: item)
            cell.imageAsset = item
        } else if case let .download(progress) = item.type {
            self.imageAssets[index].type = .download(progress: progress)
            cell.imageAsset = self.imageAssets[index]
        }
        return cell
    }
}


// MARK: UICollectionViewDelegateFlowLayout
extension ImageBrowserViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if self.isMore {
            return CGSize(width: UIScreen.main.bounds.size.width/3 - 4, height: UIScreen.main.bounds.size.width/3 - 4)
        } else {
            return CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        }
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if self.isMore {
            return 6
        } else {
            return 0
        }
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if self.isMore {
            return 2
        } else {
            return 0
        }
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if self.isMore {
            var bottomConstant: CGFloat = 0
            if #available(iOS 11.0, *) {
                bottomConstant = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
            }
            return UIEdgeInsets(top: 0, left: 0, bottom: bottomConstant, right: 0)
        } else {
            return UIEdgeInsets.zero
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }
}
