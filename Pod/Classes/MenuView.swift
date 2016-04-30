//
//  MenuView.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 5/9/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

public class MenuView: UIScrollView {
    public private(set) var menuItemViews = [MenuItemView]()
    public private(set) var currentPage: Int = 0
    public private(set) var currentMenuItemView: MenuItemView!
    internal var menuItemCount: Int {
        switch options.menuDisplayMode {
        case .Infinite: return options.menuItemCount * options.dummyMenuItemViewsSet
        default: return options.menuItemCount
        }
    }
    internal var previousPage: Int {
        return currentPage - 1 < 0 ? menuItemCount - 1 : currentPage - 1
    }
    internal var nextPage: Int {
        return currentPage + 1 > menuItemCount - 1 ? 0 : currentPage + 1
    }
    private var sortedMenuItemViews = [MenuItemView]()
    private var options: PagingMenuOptions!
    
    private let contentView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    lazy private var underlineView: UIView = {
        let view = UIView(frame: .zero)
        return view
    }()
    lazy private var roundRectView: UIView = {
        let view = UIView(frame: .zero)
        view.userInteractionEnabled = true
        return view
    }()
    private var menuViewBounces: Bool {
        switch options.menuDisplayMode {
        case .Standard(_, _, .ScrollEnabledAndBouces),
             .Infinite(_, .ScrollEnabledAndBouces): return true
        default: return false
        }
    }
    private var menuViewScrollEnabled: Bool {
        switch options.menuDisplayMode {
        case .Standard(_, _, .ScrollEnabledAndBouces),
             .Standard(_, _, .ScrollEnabled),
             .Infinite(_, .ScrollEnabledAndBouces),
             .Infinite(_, .ScrollEnabled): return true
        default: return false
        }
    }
    private var contentOffsetX: CGFloat {
        switch options.menuDisplayMode {
        case let .Standard(_, centerItem, _) where centerItem:
            return centerOfScreenWidth
        case .SegmentedControl:
            return contentOffset.x
        case .Infinite:
            return centerOfScreenWidth
        default:
            return contentOffsetXForCurrentPage
        }
    }
    private var centerOfScreenWidth: CGFloat {
        return menuItemViews[currentPage].frame.midX - UIApplication.sharedApplication().keyWindow!.bounds.width / 2
    }
    private var contentOffsetXForCurrentPage: CGFloat {
        guard menuItemCount > options.minumumSupportedViewCount else { return 0.0 }
        let ratio = CGFloat(currentPage) / CGFloat(menuItemCount - 1)
        return (contentSize.width - frame.width) * ratio
    }
    lazy private var rawIndex: (Int) -> Int = {
        let count = self.menuItemCount
        let startIndex = self.currentPage - count / 2
        return (startIndex + $0 + count) % count
    }
    
    // MARK: - Lifecycle
    
    internal init(menuItemTitles: [String], options: PagingMenuOptions) {
        super.init(frame: .zero)
        
        self.options = options
        commonInit({ self.constructMenuItemViews(menuItemTitles) })
    }
    
    internal init(menuItemImages: [UIImage], options: PagingMenuOptions) {
        super.init(frame: .zero)
        
        self.options = options
        commonInit({ self.constructMenuItemViews(menuItemImages) })
    }
    
    private func commonInit(constructor: () -> Void) {
        setupScrollView()
        setupContentView()
        layoutContentView()
        setupRoundRectViewIfNeeded()
        constructor()
        layoutMenuItemViews()
        setupUnderlineViewIfNeeded()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        adjustmentContentInsetIfNeeded()
    }
    
    // MARK: - Public method
    
    internal func moveToMenu(page: Int, animated: Bool) {
        let duration = animated ? options.animationDuration : 0
        currentPage = page
        
        let menuItemView = menuItemViews[page]
        let _ = menuItemViews.indexOf(menuItemView)
        
        // hide menu view when constructing itself
        if !animated {
            alpha = 0
        }
        UIView.animateWithDuration(duration, animations: { [weak self] () -> Void in
            guard let _ = self else { return }
            
            self!.focusMenuItem()
            if self!.options.menuSelectedItemCenter {
                self!.positionMenuItemViews()
            }
        }) { [weak self] (_) in
            guard let _ = self else { return }
            
            // relayout menu item views dynamically
            if case .Infinite = self!.options.menuDisplayMode {
                self!.relayoutMenuItemViews()
            }
            if self!.options.menuSelectedItemCenter {
                self!.positionMenuItemViews()
            }
            self!.setNeedsLayout()
            self!.layoutIfNeeded()
            
            // show menu view when constructing is done
            if !animated {
                self!.alpha = 1
            }
        }
    }
    
    internal func updateMenuViewConstraints(size size: CGSize) {
        if case .SegmentedControl = options.menuDisplayMode {
            menuItemViews.forEach { $0.updateConstraints(size) }
        }
        contentView.setNeedsLayout()
        contentView.layoutIfNeeded()

        animateUnderlineViewIfNeeded()
        animateRoundRectViewIfNeeded()
    }
    
    internal func cleanup() {
        contentView.removeFromSuperview()
        switch options.menuItemMode {
        case .Underline: underlineView.removeFromSuperview()
        case .RoundRect: roundRectView.removeFromSuperview()
        case .None: break
        }
        
        if !menuItemViews.isEmpty {
            menuItemViews.forEach {
                $0.cleanup()
                $0.removeFromSuperview()
            }
        }
    }
    
    // MARK: - Private method
    
    private func setupScrollView() {
        backgroundColor = options.backgroundColor
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        bounces = menuViewBounces
        scrollEnabled = menuViewScrollEnabled
        decelerationRate = options.deceleratingRate
        scrollsToTop = false
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupContentView() {
        addSubview(contentView)
    }
    
    private func layoutContentView() {
        // H:|[contentView]|
        // V:|[contentView(==scrollView)]|
        NSLayoutConstraint.activateConstraints([
            contentView.leadingAnchor.constraintEqualToAnchor(leadingAnchor),
            contentView.trailingAnchor.constraintEqualToAnchor(trailingAnchor),
            contentView.topAnchor.constraintEqualToAnchor(topAnchor),
            contentView.bottomAnchor.constraintEqualToAnchor(bottomAnchor),
            contentView.heightAnchor.constraintEqualToAnchor(heightAnchor)
            ])
    }
    
    private func constructMenuItemViews(titles: [String]) {
        constructMenuItemViews({ MenuItemView(title: titles[$0], options: self.options, addDivider: $1) })
    }
    
    private func constructMenuItemViews(images: [UIImage]) {
        constructMenuItemViews({ MenuItemView(image: images[$0], options: self.options, addDivider: $1) })
    }
    
    private func constructMenuItemViews(constructor: (Int, Bool) -> MenuItemView) {
        for index in 0..<menuItemCount {
            let addDivider = index < menuItemCount - 1
            let menuItemView = constructor(index % options.menuItemCount, addDivider)
            menuItemView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(menuItemView)
            
            menuItemViews.append(menuItemView)
        }
        
        sortMenuItemViews()
    }
    
    private func sortMenuItemViews() {
        if !sortedMenuItemViews.isEmpty {
            sortedMenuItemViews.removeAll()
        }
        
        if case .Infinite = options.menuDisplayMode {
            for i in 0..<menuItemCount {
                let index = rawIndex(i)
                sortedMenuItemViews.append(menuItemViews[index])
            }
        } else {
            sortedMenuItemViews = menuItemViews
        }
    }
    
    private func layoutMenuItemViews() {
        NSLayoutConstraint.deactivateConstraints(contentView.constraints)
        
        for (index, menuItemView) in sortedMenuItemViews.enumerate() {
            if index == 0 {
                // H:|[menuItemView]
                menuItemView.leadingAnchor.constraintEqualToAnchor(contentView.leadingAnchor).active = true
            } else  {
                if index == sortedMenuItemViews.count - 1 {
                    // H:[menuItemView]|
                    menuItemView.trailingAnchor.constraintEqualToAnchor(contentView.trailingAnchor).active = true
                }
                // H:[previousMenuItemView][menuItemView]
                let previousMenuItemView = sortedMenuItemViews[index - 1]
                previousMenuItemView.trailingAnchor.constraintEqualToAnchor(menuItemView.leadingAnchor, constant: 0).active = true
            }
            
            // V:|[menuItemView]|
            NSLayoutConstraint.activateConstraints([
                menuItemView.topAnchor.constraintEqualToAnchor(contentView.topAnchor),
                menuItemView.bottomAnchor.constraintEqualToAnchor(contentView.bottomAnchor)
                ])
        }
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    private func setupUnderlineViewIfNeeded() {
        guard case let .Underline(height, color, horizontalPadding, verticalPadding) = options.menuItemMode else { return }
        
        let width = menuItemViews[currentPage].bounds.width - horizontalPadding * 2
        underlineView.frame = CGRectMake(horizontalPadding, options.menuHeight - (height + verticalPadding), width, height)
        underlineView.backgroundColor = color
        contentView.addSubview(underlineView)
    }
    
    private func setupRoundRectViewIfNeeded() {
        guard case let .RoundRect(radius, _, verticalPadding, selectedColor) = options.menuItemMode else { return }
        
        let height = options.menuHeight - verticalPadding * 2
        roundRectView.frame = CGRectMake(0, verticalPadding, 0, height)
        roundRectView.layer.cornerRadius = radius
        roundRectView.backgroundColor = selectedColor
        contentView.addSubview(roundRectView)
    }
    
    private func animateUnderlineViewIfNeeded() {
        guard case let .Underline(_, _, horizontalPadding, _) = options.menuItemMode else { return }
        
        let targetFrame = menuItemViews[currentPage].frame
        underlineView.frame.origin.x = targetFrame.minX + horizontalPadding
        underlineView.frame.size.width = targetFrame.width - horizontalPadding * 2
    }
    
    private func animateRoundRectViewIfNeeded() {
        guard case let .RoundRect(_, horizontalPadding, _, _) = options.menuItemMode else { return }
        
        let targetFrame = menuItemViews[currentPage].frame
        roundRectView.frame.origin.x = targetFrame.minX + horizontalPadding
        roundRectView.frame.size.width = targetFrame.width - horizontalPadding * 2
    }

    private func relayoutMenuItemViews() {
        sortMenuItemViews()
        layoutMenuItemViews()
    }

    private func positionMenuItemViews() {
        contentOffset.x = contentOffsetX
        animateUnderlineViewIfNeeded()
        animateRoundRectViewIfNeeded()
    }
    
    private func adjustmentContentInsetIfNeeded() {
        switch options.menuDisplayMode {
        case let .Standard(_, centerItem, _) where centerItem: break
        default: return
        }
        
        let firstMenuView = menuItemViews.first!
        let lastMenuView = menuItemViews.last!
        
        var inset = contentInset
        let halfWidth = frame.width / 2
        inset.left = halfWidth - firstMenuView.frame.width / 2
        inset.right = halfWidth - lastMenuView.frame.width / 2
        contentInset = inset
    }
    
    private func focusMenuItem() {
        let selected: (MenuItemView) -> Bool = { self.menuItemViews.indexOf($0) == self.currentPage }
        
        // make selected item focused
        menuItemViews.forEach {
            $0.selected = selected($0)
            if $0.selected {
                self.currentMenuItemView = $0
            }
        }

        // make selected item foreground
        sortedMenuItemViews.forEach { $0.layer.zPosition = selected($0) ? 0 : -1 }
        
        setNeedsLayout()
        layoutIfNeeded()
    }
}