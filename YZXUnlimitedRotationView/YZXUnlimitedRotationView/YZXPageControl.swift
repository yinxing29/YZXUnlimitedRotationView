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
    
    // 当前选中的page
    var currentPage = 0 {
        didSet {
            p_refreshUI()
        }
    }
    
    // 总page数量
    var numberOfPages = 0
    
    private var lastPage: Int?
    
    // 添加到父视图时更新UI
    override func willMove(toSuperview newSuperview: UIView?) {
        updateDots()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        axis = .horizontal
        alignment = .center
    }
    
    // 更新试图
    func updateDots() {
        // 设置默认图片
        if activeImage == nil {
            activeImage = UIImage.yzx_image(color: .orange, size: CGSize(width: 8.0, height: 8.0), cornerRadius: 4.0)
        }
        
        if inactiveImage == nil {
            inactiveImage = UIImage.yzx_image(color: .gray, size: CGSize(width: 8.0, height: 8.0), cornerRadius: 4.0)
        }
        
        // page间隔为图片宽度
        spacing = min(activeImage!.size.width, inactiveImage!.size.width)
        
        // 移除所有视图，重新布局
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
        
        // 自适应宽度
        let imageWidth = max(activeImage?.size.width ?? 0.0, inactiveImage?.size.width ?? 0.0)
        let pageWidth = imageWidth * CGFloat(numberOfPages) + spacing * CGFloat(numberOfPages - 1)
        var rect = frame
        rect.size.width = pageWidth
        frame = rect
    }
    
    /// 刷新选中page状态
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
    /// 生成纯色图片
    static func yzx_image(color: UIColor, size: CGSize, cornerRadius: CGFloat) -> UIImage? {
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
