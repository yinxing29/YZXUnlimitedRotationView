//
//  YZXUnlimitedRotationView.swift
//  YZXUnlimitedRotationView
//
//  Created by yinxing on 2022/6/28.
//

import Foundation
import UIKit

enum YZXUnlimitedRotationViewPageType {
    case left
    case center
    case right
}

protocol YZXUnlimitedRotationViewDelegate: NSObjectProtocol {
    func yzx_unlimitedRotationNumbers(view: YZXUnlimitedRotationView) -> Int
    
    func yzx_unlimitedRotationView(view: YZXUnlimitedRotationView, index: Int) -> UITableViewCell
    
    func yzx_unlimitedRotationView(view: YZXUnlimitedRotationView, didSelectedIndex index: Int) -> Void
}

extension YZXUnlimitedRotationViewDelegate {
    func yzx_unlimitedRotationView(view: YZXUnlimitedRotationView, didSelectedIndex index: Int) -> Void {
        
    }
}

class YZXUnlimitedRotationView: UIView {
    
    //MARK: - 公有属性
    weak var delegate: YZXUnlimitedRotationViewDelegate?
    
    var isAutoScroll = true
    
    var autoScrollTimeInterval = 2.0
    
    var isShowPageControl = false
    
    var pageType: YZXUnlimitedRotationViewPageType = .left
    
    // pageControl图片
    var activeImage: UIImage?
    
    // pageControl选中图片
    var inactiveImage: UIImage?
    //MARK: - --------------------- 公有属性 END ---------------------
    
    //MARK: - 私有属性
    private var leftView: UITableViewCell?
    
    private var centerView: UITableViewCell?
    
    private var rightView: UITableViewCell?
    
    private var contentWidth: CGFloat = 0.0
    
    private var contentHeight: CGFloat = 0.0
    
    private var totalNumber = 0
    
    private var currentIndex = 0
    
    private var isFirstLayout = true
    
    private var cacheCells = [UITableViewCell]()
    
    private var timer: Timer?
    
    private var pageControl: YZXPageControl = {
        let view = YZXPageControl(frame: .zero)
        return view
    }()
    //MARK: - --------------------- 私有属性 END ---------------------
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = true
        backgroundColor = .white
        p_initView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if isFirstLayout {
            contentWidth = bounds.size.width
            contentHeight = bounds.size.height - (isShowPageControl ? 30.0 : 0.0)
            reloadData()
            isFirstLayout = false
        }
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview == nil {
            p_releaseTimer()
        }
    }
    
    //MARK: - init
    private func p_initView() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(pan(sender:)))
        pan.delegate = self
        addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap))
        addGestureRecognizer(tap)
    }
    //MARK: - --------------------- init END ---------------------
    
    //MARK: - 手势事件
    @objc func tap() {
        delegate?.yzx_unlimitedRotationView(view: self, didSelectedIndex: currentIndex)
    }
    
    @objc func pan(sender: UIPanGestureRecognizer) {
        guard let currentView = centerView else {
            return
        }
        
        var startPoint: CGPoint = .zero
        var endPoint: CGPoint = .zero
        let point = sender.translation(in: self)
        // 手势向左为负，向右为正
        let velocity = sender.velocity(in: self)
        switch sender.state {
        case .began:
            startPoint = point
            
            if isAutoScroll {
                p_releaseTimer()
            }
        case .changed:
            endPoint = point

            let pointX = endPoint.x - startPoint.x
            p_viewScroll(x: pointX)
            
            // 重置偏移量
            sender.setTranslation(.zero, in: self)
        case .ended:
            if velocity.x > 500 {
                p_backScroll()
                return
            }else if velocity.x < -500 {
                p_nextScroll()
                return
            }
            
            let needScrollPage = (currentView.frame.origin.x >= contentWidth / 2.0 || currentView.frame.origin.x <= -contentWidth / 2.0)
            if !needScrollPage {
                UIView.animate(withDuration: 0.3) {
                    self.p_resetLayout()
                } completion: { finished in
                    if self.isAutoScroll {
                        self.p_createTimer()
                    }
                }
                return
            }
            if velocity.x > 0.0 {
                p_backScroll()
            }else {
                p_nextScroll()
            }
        default:
            break
        }
    }
    //MARK: - --------------------- 手势事件 END ---------------------
    
    //MARK: - 私有方法
    func reloadData() {
        if delegate == nil {
            return
        }
        
        if let number = delegate?.yzx_unlimitedRotationNumbers(view: self) {
            totalNumber = number
        }
        
        if totalNumber == 0 {
            return
        }
        
        if let backView = delegate?.yzx_unlimitedRotationView(view: self, index: currentIndex - 1 < 0 ? (totalNumber - 1) : (currentIndex - 1)) {
            leftView = backView
            addSubview(backView)
        }
        
        if let currentView = delegate?.yzx_unlimitedRotationView(view: self, index: currentIndex) {
            centerView = currentView
            addSubview(currentView)
        }
        
        if let nextView = delegate?.yzx_unlimitedRotationView(view: self, index: (currentIndex + 1) % totalNumber) {
            rightView = nextView
            addSubview(nextView)
        }
        
        leftView?.frame = CGRect(x: -contentWidth, y: 0.0, width: contentWidth, height: contentHeight)
        centerView?.frame = CGRect(x: 0.0, y: 0.0, width: contentWidth, height: contentHeight)
        rightView?.frame = CGRect(x: contentWidth, y: 0.0, width: contentWidth, height: contentHeight)
        
        if isShowPageControl {
            contentHeight = bounds.size.height - 30.0
            pageControl.isHidden = !isShowPageControl
            
            pageControl.frame = CGRect(x: 0.0, y: contentHeight, width: 100, height: 30.0)
            pageControl.activeImage = activeImage
            pageControl.inactiveImage = inactiveImage
            pageControl.numberOfPages = totalNumber
            pageControl.currentPage = currentIndex
            pageControl.updateDots()
            var center = pageControl.center
            if pageType == .center {
                center.x = contentWidth / 2.0
            }else if pageType == .right {
                center.x = contentWidth - pageControl.bounds.size.width / 2.0
            }
            pageControl.center = center
            
            if pageControl.superview == nil {
                addSubview(pageControl)
            }
        }
        
        if isAutoScroll {
            p_createTimer()
        }
    }
    
    private func p_viewScroll(x: CGFloat) {
        var leftRect = leftView?.frame ?? .zero
        var centerRect = centerView?.frame ?? .zero
        var righRect = rightView?.frame ?? .zero
        
        leftRect.origin.x += x
        centerRect.origin.x += x
        righRect.origin.x += x
        
        leftView?.frame = leftRect
        centerView?.frame = centerRect
        rightView?.frame = righRect
    }
    
    private func p_nextScroll() {
        currentIndex = (currentIndex + 1) % totalNumber
        UIView.animate(withDuration: 0.3) { [self] in
            leftView?.frame = CGRect(x: -contentWidth * 2.0, y: 0.0, width: contentWidth, height: contentHeight)
            centerView?.frame = CGRect(x: -contentWidth, y: 0.0, width: contentWidth, height: contentHeight)
            rightView?.frame = CGRect(x: 0.0, y: 0.0, width: contentWidth, height: contentHeight)
        } completion: { [self] finished in
            if let backView = leftView {
                p_AddToCache(cell: backView)
                backView.removeFromSuperview()
            }
            leftView = centerView
            centerView = rightView
            
            if let nextView = delegate?.yzx_unlimitedRotationView(view: self, index: currentIndex) {
                rightView = nextView
                addSubview(nextView)
            }
            
            pageControl.currentPage = currentIndex

            p_resetLayout()
            
            if timer == nil && isAutoScroll {
                p_createTimer()
            }
        }
    }
    
    private func p_backScroll() {
        currentIndex = (currentIndex - 1 < 0 ? (totalNumber - 1) : (currentIndex - 1))
        UIView.animate(withDuration: 0.3) { [self] in
            leftView?.frame = CGRect(x: 0.0, y: 0.0, width: contentWidth, height: contentHeight)
            centerView?.frame = CGRect(x: contentWidth, y: 0.0, width: contentWidth, height: contentHeight)
            rightView?.frame = CGRect(x: contentWidth * 2.0, y: 0.0, width: contentWidth, height: contentHeight)
        } completion: { [self] finished in
            if let nextView = rightView {
                p_AddToCache(cell: nextView)
                nextView.removeFromSuperview()
            }
            rightView = centerView
            centerView = leftView
            if let backView = delegate?.yzx_unlimitedRotationView(view: self, index: currentIndex) {
                leftView = backView
                addSubview(backView)
            }
            
            pageControl.currentPage = currentIndex

            p_resetLayout()
            
            if timer == nil && isAutoScroll {
                p_createTimer()
            }
        }
    }
    
    private func p_resetLayout() {
        leftView?.frame = CGRect(x: -contentWidth, y: 0.0, width: contentWidth, height: contentHeight)
        centerView?.frame = CGRect(x: 0.0, y: 0.0, width: contentWidth, height: contentHeight)
        rightView?.frame = CGRect(x: contentWidth, y: 0.0, width: contentWidth, height: contentHeight)
    }
    
    private func p_AddToCache(cell: UITableViewCell) {
        if cacheCells.contains(where: { $0.reuseIdentifier == cell.reuseIdentifier }) {
            return
        }
        cacheCells.append(cell)
    }
    
    private func p_createTimer() {
        p_resetLayout()
        
        if totalNumber == 0 {
            return
        }
        
        timer = Timer.scheduledTimer(timeInterval: autoScrollTimeInterval, target: self, selector: #selector(p_timer), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .default)
    }
    
    private func p_releaseTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc func p_timer() {
        p_nextScroll()
    }
    //MARK: - --------------------- 私有方法 END ---------------------
    
    //MARK: - 公用方法
    func dequeueReusableCell(withReuseIdentifier identifier: String, index: Int) -> UITableViewCell? {
        if let index = cacheCells.firstIndex(where: { $0.reuseIdentifier == identifier }) {
            let cell = cacheCells[index]
            cacheCells.remove(at: index)
            return cell
        }
        return nil
    }
    //MARK: - --------------------- 公用方法 END ---------------------
}

extension YZXUnlimitedRotationView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
