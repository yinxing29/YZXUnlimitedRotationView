//
//  YZXUnlimitedRotationViewCenterOutExtension.swift
//  YZXUnlimitedRotationView
//
//  Created by yinxing on 2023/5/4.
//

import Foundation
import UIKit

extension YZXUnlimitedRotationView {
    
    func p_centerOutReloadData() {
        if let spacing = delegate?.yzx_unlimitedRotationViewHorizontalSpacing(swipe: self) {
            horizontalSpacing = spacing
        }
        
        if let spacing = delegate?.yzx_unlimitedRotationViewVerticalSpacing(swipe: self) {
            verticalSpacing = spacing
        }
        
        if isStackCard {
            leftView?.alpha = 0.3
            rightView?.alpha = 0.3
            centerView?.alpha = 1.0
        }
        
        // 设置各视图位置
        leftView?.frame = CGRect(x: 0.0, y: verticalSpacing, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight - verticalSpacing * 2.0)
        if currentIndex == 0 && !isRotation {
            leftView?.alpha = 0.0
        }else {
            leftView?.alpha = isStackCard ? 0.3 : 1.0
        }
        centerView?.frame = CGRect(x: horizontalSpacing, y: 0.0, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight)
        rightView?.frame = CGRect(x: horizontalSpacing * 2.0, y: verticalSpacing, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight - verticalSpacing * 2.0)
        if currentIndex == totalNumber - 1 && !isRotation {
            rightView?.alpha = 0.0
        }else {
            rightView?.alpha = isStackCard ? 0.3 : 1.0
        }
        
        // 自动滑动，启动timer
        if isAutoScroll && isRotation {
            p_createTimer()
        }
    }
    
    func p_centerOutNextScroll() {
        if currentIndex == totalNumber - 1 && !isRotation {
            return
        }
        
        // 获取下一个视图的index
        currentIndex = (currentIndex + 1) % totalNumber
        UIView.animate(withDuration: 0.3) { [self] in
            centerView?.frame = CGRect(x: 0.0, y: verticalSpacing, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight - verticalSpacing * 2.0)
            if isStackCard {
                centerView?.alpha = 0.6
            }
        } completion: { [self] finished in
            leftView?.alpha = 0.0
            
            if let removeView = viewRemove, p_isNeedAddToCache(cell: removeView) {
                cacheCells.append(removeView)
                removeView.alpha = 1.0
                removeView.removeFromSuperview()
            }
            
            viewRemove = leftView
            leftView = centerView
            centerView = rightView
            
            if let center = centerView, let left = leftView {
                insertSubview(left, belowSubview: center)
            }
            
            // 获取新的右边视图
            if let nextView = delegate?.yzx_unlimitedRotationView(view: self, index: (currentIndex + 1) % totalNumber) {
                nextView.removeFromSuperview()
                nextView.frame = CGRect(x: horizontalSpacing * 2.0, y: verticalSpacing, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight - verticalSpacing * 2.0)
                rightView = nextView
                if let left = leftView {
                    insertSubview(nextView, belowSubview: left)
                }
            }
            
            centerView?.isUserInteractionEnabled = true
            leftView?.isUserInteractionEnabled = false
            rightView?.isUserInteractionEnabled = false
            
            if isStackCard {
                leftView?.alpha = 0.3
                rightView?.alpha = 0.3
                centerView?.alpha = 0.3
            }
            
            if currentIndex == 0 && !isRotation {
                leftView?.alpha = 0.0
            }else {
                leftView?.alpha = isStackCard ? 0.3 : 1.0
            }
            
            if currentIndex == totalNumber - 1 && !isRotation {
                rightView?.alpha = 0.0
            }else {
                rightView?.alpha = isStackCard ? 0.3 : 1.0
            }
            
            UIView.animate(withDuration: 0.2) { [self] in
                centerView?.alpha = 1.0
                centerView?.frame = CGRect(x: horizontalSpacing, y: 0.0, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight)
                rightView?.frame = CGRect(x: horizontalSpacing * 2.0, y: verticalSpacing, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight - verticalSpacing * 2.0)
            } completion: { [self] finished in
                if timer == nil && isAutoScroll && isRotation {
                    p_createTimer()
                }
            }
            
            pageControl.currentPage = currentIndex
        }
    }
    
    func p_centerOutBackScroll() {
        if currentIndex == 0 && !isRotation {
            return
        }
        
        // 获取上一个视图的index
        currentIndex = (currentIndex - 1 < 0 ? (totalNumber - 1) : (currentIndex - 1))
        UIView.animate(withDuration: 0.3) { [self] in
            centerView?.frame = CGRect(x: horizontalSpacing * 2.0, y: verticalSpacing, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight - verticalSpacing * 2.0)
            if isStackCard {
                centerView?.alpha = 0.6
            }
        } completion: { [self] finished in
            rightView?.alpha = 0.0
            
            if let removeView = viewRemove, p_isNeedAddToCache(cell: removeView) {
                cacheCells.append(removeView)
                removeView.alpha = 1.0
                removeView.removeFromSuperview()
            }
            
            viewRemove = rightView
            rightView = centerView
            centerView = leftView
            
            if let center = centerView, let right = rightView {
                insertSubview(right, belowSubview: center)
            }
            
            if let cell = delegate?.yzx_unlimitedRotationView(view: self, index: (currentIndex - 1 < 0 ? (totalNumber - 1) : (currentIndex - 1))) {
                cell.removeFromSuperview()
                cell.frame = CGRect(x: 0.0, y: verticalSpacing, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight - verticalSpacing * 2.0)
                leftView = cell
                
                if let right = rightView {
                    insertSubview(cell, aboveSubview: right)
                }
            }
            
            centerView?.isUserInteractionEnabled = true
            leftView?.isUserInteractionEnabled = false
            rightView?.isUserInteractionEnabled = false
            
            if isStackCard {
                leftView?.alpha = 0.3
                rightView?.alpha = 0.3
                centerView?.alpha = 0.3
            }
            
            // 如果滑到第一个。隐藏左边试图
            if currentIndex == 0 && !isRotation {
                leftView?.alpha = 0.0
            }else {
                leftView?.alpha = isStackCard ? 0.3 : 1.0
            }
            
            // 如果滑到最后一个。隐藏左边试图
            if currentIndex == totalNumber - 1 && !isRotation {
                rightView?.alpha = 0.0
            }else {
                rightView?.alpha = isStackCard ? 0.3 : 1.0
            }
            
            
            UIView.animate(withDuration: 0.5) { [self] in
                centerView?.alpha = 1.0
                centerView?.frame = CGRect(x: horizontalSpacing, y: 0.0, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight)
                rightView?.frame = CGRect(x: horizontalSpacing * 2.0, y: verticalSpacing, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight - verticalSpacing * 2.0)
                leftView?.frame = CGRect(x: 0.0, y: verticalSpacing, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight - verticalSpacing * 2.0)
            } completion: { [self] finished in
                if timer == nil && isAutoScroll && isRotation {
                    p_createTimer()
                }
            }
            
            pageControl.currentPage = currentIndex
        }
    }
}
