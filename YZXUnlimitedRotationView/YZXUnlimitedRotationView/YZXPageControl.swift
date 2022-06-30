//
//  YZXPageControl.swift
//  YZXUnlimitedRotationView
//
//  Created by yinxing on 2022/6/23.
//

import Foundation
import UIKit

class YZXPageControl: UIStackView {
    
    // 选中图片
    var activeImage: UIImage?
    
    // 未选中图片
    var inactiveImage: UIImage?
    
    var currentPage = 0 {
        didSet {
            p_refreshUI()
        }
    }
    
    var numberOfPages = 0
    
    var lastPage: Int?
    
    override func willMove(toSuperview newSuperview: UIView?) {
        updateDots()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        axis = .horizontal
        spacing = 8.0
        alignment = .center
    }
    
    // 更新试图
    func updateDots() {
        if activeImage == nil {
            activeImage = UIImage.image(color: .orange, size: CGSize(width: 8.0, height: 8.0), cornerRadius: 4.0)
        }
        
        if inactiveImage == nil {
            inactiveImage = UIImage.image(color: .gray, size: CGSize(width: 8.0, height: 8.0), cornerRadius: 4.0)
        }
        
        arrangedSubviews.forEach( { $0.removeFromSuperview() } )
        
        for index in 0..<numberOfPages {
            let imageView = UIImageView(frame: .zero)
            if index == currentPage {
                lastPage = currentPage
                imageView.image = activeImage
            }else {
                imageView.image = inactiveImage
            }
            addArrangedSubview(imageView)
        }
        
        let imageWidth = max(activeImage?.size.width ?? 0.0, inactiveImage?.size.width ?? 0.0)
        let pageWidth = imageWidth * CGFloat(numberOfPages) + spacing * CGFloat(numberOfPages - 1)
        var rect = frame
        rect.size.width = pageWidth
        frame = rect
    }
    
    private func p_refreshUI() {
        guard currentPage < arrangedSubviews.count else {
            return
        }
        
        if let page = lastPage, page < arrangedSubviews.count, let imageView = arrangedSubviews[page] as? UIImageView {
            imageView.image = inactiveImage
        }
        
        if let imageView = arrangedSubviews[currentPage] as? UIImageView {
            imageView.image = activeImage
        }
        
        lastPage = currentPage
    }
}

extension UIImage {
    static func image(color: UIColor, size: CGSize, cornerRadius: CGFloat) -> UIImage? {
        if size.width <= 0.0 || size.height <= 0.0 {
            return nil
        }
        
        let rect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        path.addClip()
        
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
