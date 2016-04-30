//
//  MenuItemView.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 5/9/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

public class MenuItemView: UIView {
    
    lazy public var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 1
        label.textAlignment = .Center
        label.userInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    lazy public var menuImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.userInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    public internal(set) var selected: Bool = false {
        didSet {
            if case .RoundRect = options.menuItemMode {
                backgroundColor = UIColor.clearColor()
            } else {
                backgroundColor = selected ? options.selectedBackgroundColor : options.backgroundColor
            }
            
            switch options.menuItemViewContent {
            case .Text:
                titleLabel.textColor = selected ? options.selectedTextColor : options.textColor
                titleLabel.font = selected ? options.selectedFont : options.font
                
                // adjust label width if needed
                let labelSize = calculateLableSize()
                widthConstraint.constant = labelSize.width
            case .Image: break
            }
        }
    }
    lazy public private(set) var dividerImageView: UIImageView? = {
        let imageView = UIImageView(image: self.options.menuItemDividerImage)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    private var options: PagingMenuOptions!
    private var widthConstraint: NSLayoutConstraint!
    private var labelSize: CGSize {
        guard let text = titleLabel.text else { return .zero }
        return NSString(string: text).boundingRectWithSize(CGSizeMake(CGFloat.max, CGFloat.max), options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName: titleLabel.font], context: nil).size
    }
    private let labelWidth: (CGSize, PagingMenuOptions.MenuItemWidthMode) -> CGFloat = { size, widthMode in
        switch widthMode {
        case .Flexible: return ceil(size.width)
        case .Fixed(let width): return width
        }
    }
    private var horizontalMargin: CGFloat {
        switch options.menuDisplayMode {
        case .SegmentedControl: return 0.0
        default: return options.menuItemMargin
        }
    }
    
    // MARK: - Lifecycle
    
    internal init(title: String, options: PagingMenuOptions, addDivider: Bool) {
        super.init(frame: .zero)
        self.options = options
        
        commonInit(addDivider) {
            self.setupLabel(title)
            self.layoutLabel()
        }
    }
    
    internal init(image: UIImage, options: PagingMenuOptions, addDivider: Bool) {
        super.init(frame: .zero)
        self.options = options
        
        commonInit(addDivider) {
            self.setupImageView(image)
            self.layoutImageView()
        }
    }
    
    private func commonInit(addDivider: Bool, setup: () -> Void) {
        setupView()
        
        setup()
        
        if let _ = options.menuItemDividerImage where addDivider {
            setupDivider()
            layoutDivider()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    // MARK: - Cleanup
    
    internal func cleanup() {
        switch options.menuItemViewContent {
        case .Text: titleLabel.removeFromSuperview()
        case .Image: menuImageView.removeFromSuperview()
        }
        
        dividerImageView?.removeFromSuperview()
    }
    
    // MARK: - Constraints manager
    
    internal func updateConstraints(size: CGSize) {
        // set width manually to support ratotaion
        switch (options.menuDisplayMode, options.menuItemViewContent) {
        case (.SegmentedControl, .Text):
            let labelSize = calculateLableSize(size)
            widthConstraint.constant = labelSize.width
        case (.SegmentedControl, .Image):
            widthConstraint.constant = size.width / CGFloat(options.menuItemCount)
        default: break
        }
    }
    
    // MARK: - Constructor
    
    private func setupView() {
        if case .RoundRect = options.menuItemMode {
            backgroundColor = UIColor.clearColor()
        } else {
            backgroundColor = options.backgroundColor
        }
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupLabel(title: String) {
        titleLabel.text = title
        titleLabel.textColor = options.textColor
        titleLabel.font = options.font
        addSubview(titleLabel)
    }
    
    private func setupImageView(image: UIImage) {
        menuImageView.image = image
        addSubview(menuImageView)
    }
    
    private func setupDivider() {
        guard let dividerImageView = dividerImageView else { return }
        
        addSubview(dividerImageView)
    }

    private func layoutLabel() {
        let labelSize = calculateLableSize()
        
        // H:|[titleLabel(==labelSize.width)]|
        // V:|[titleLabel]|
        widthConstraint = titleLabel.widthAnchor.constraintEqualToConstant(labelSize.width)
        NSLayoutConstraint.activateConstraints([
            titleLabel.leadingAnchor.constraintEqualToAnchor(leadingAnchor),
            titleLabel.trailingAnchor.constraintEqualToAnchor(trailingAnchor),
            widthConstraint,
            titleLabel.topAnchor.constraintEqualToAnchor(topAnchor),
            titleLabel.bottomAnchor.constraintEqualToAnchor(bottomAnchor),
            ])
    }
    
    private func layoutImageView() {
        guard let image = menuImageView.image else { return }
        
        let width: CGFloat
        switch options.menuDisplayMode {
        case .SegmentedControl: width = UIApplication.sharedApplication().keyWindow!.bounds.size.width / CGFloat(options.menuItemCount)
        default: width = image.size.width
        }
        widthConstraint = menuImageView.widthAnchor.constraintEqualToConstant(width)
        
        // H:|[menuImageView(image.size.width)]|
        // V:|[menuImageView(image.size.height)]|
        NSLayoutConstraint.activateConstraints([
            menuImageView.leadingAnchor.constraintEqualToAnchor(leadingAnchor),
            menuImageView.trailingAnchor.constraintEqualToAnchor(trailingAnchor),
            widthConstraint,
            menuImageView.topAnchor.constraintEqualToAnchor(topAnchor),
            menuImageView.bottomAnchor.constraintEqualToAnchor(bottomAnchor)
            ])
    }
    
    private func layoutDivider() {
        guard let dividerImageView = dividerImageView else { return }
        
        NSLayoutConstraint.activateConstraints([
            dividerImageView.centerYAnchor.constraintEqualToAnchor(centerYAnchor, constant: 1.0),
            dividerImageView.trailingAnchor.constraintEqualToAnchor(trailingAnchor)
            ])
    }

    // MARK: - Size calculator
    
    private func calculateLableSize(size: CGSize = UIApplication.sharedApplication().keyWindow!.bounds.size) -> CGSize {
        guard let _ = titleLabel.text else { return .zero }
        
        let itemWidth: CGFloat
        switch options.menuDisplayMode {
        case let .Standard(widthMode, _, _):
            itemWidth = labelWidth(labelSize, widthMode)
        case .SegmentedControl:
            itemWidth = size.width / CGFloat(options.menuItemCount)
        case let .Infinite(widthMode, _):
            itemWidth = labelWidth(labelSize, widthMode)
        }
        
        let itemHeight = floor(labelSize.height)
        return CGSizeMake(itemWidth + horizontalMargin * 2, itemHeight)
    }
}
