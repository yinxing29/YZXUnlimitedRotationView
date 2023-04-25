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
    
    // pageControl高度
    var pageControlHeight = 30.0
    
    // pageControl选中图片
    var activeImage: UIImage?
    
    // pageControl图片
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
            contentHeight = bounds.size.height - (isShowPageControl ? pageControlHeight : 0.0)
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
    /// 点击手势事件
    @objc func tap() {
        if totalNumber == 0 {
            return
        }
        delegate?.yzx_unlimitedRotationView(view: self, didSelectedIndex: currentIndex)
    }
    
    /// 拖拽手势事件
    @objc func pan(sender: UIPanGestureRecognizer) {
        guard let currentView = centerView, totalNumber > 0 else {
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
            
            // 如果自动滑动，销毁timer
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
            // 快速滑动，直接切换视图
            if velocity.x > 500 {
                p_backScroll()
                return
            }else if velocity.x < -500 {
                p_nextScroll()
                return
            }
            
            // 滑动超过视图的一半，切换视图
            let needScrollPage = (currentView.frame.origin.x >= contentWidth / 2.0 || currentView.frame.origin.x <= -contentWidth / 2.0)
            if !needScrollPage {
                UIView.animate(withDuration: 0.3) {
                    self.p_resetLayout()
                } completion: { finished in
                    // 自动滑动开启，手势滑动结束，开启timer
                    if self.isAutoScroll {
                        self.p_createTimer()
                    }
                }
                return
            }
            
            if velocity.x >= 0.0 {
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
    /// 刷新视图
    func reloadData() {
        // 销毁旧timer，后续重新启动新timer
        p_releaseTimer()
        
        if delegate == nil {
            return
        }
        
        // 获取视图总数量
        if let number = delegate?.yzx_unlimitedRotationNumbers(view: self) {
            totalNumber = number
        }
        
        if totalNumber == 0 {
            return
        }
        
        // 获取左边视图
        if let backView = delegate?.yzx_unlimitedRotationView(view: self, index: currentIndex - 1 < 0 ? (totalNumber - 1) : (currentIndex - 1)) {
            leftView = backView
            addSubview(backView)
        }
        
        // 获取当前展示的视图
        if let currentView = delegate?.yzx_unlimitedRotationView(view: self, index: currentIndex) {
            centerView = currentView
            addSubview(currentView)
        }
        
        // 获取右边视图
        if let nextView = delegate?.yzx_unlimitedRotationView(view: self, index: (currentIndex + 1) % totalNumber) {
            rightView = nextView
            addSubview(nextView)
        }
        
        // 设置各视图位置
        leftView?.frame = CGRect(x: -contentWidth, y: 0.0, width: contentWidth, height: contentHeight)
        centerView?.frame = CGRect(x: 0.0, y: 0.0, width: contentWidth, height: contentHeight)
        rightView?.frame = CGRect(x: contentWidth, y: 0.0, width: contentWidth, height: contentHeight)
        
        // 是否显示pageControl（pageControl默认高度为30.0）
        if isShowPageControl {
            contentHeight = bounds.size.height - pageControlHeight
            pageControl.isHidden = !isShowPageControl
            
            pageControl.frame = CGRect(x: 0.0, y: contentHeight, width: 100, height: pageControlHeight)
            pageControl.activeImage = activeImage
            pageControl.inactiveImage = inactiveImage
            pageControl.numberOfPages = totalNumber
            pageControl.currentPage = currentIndex
            pageControl.updateDots()
            // 设置pageControl位置
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
        
        // 自动滑动，启动timer
        if isAutoScroll {
            p_createTimer()
        }
    }
    
    /// 手势滑动视图
    /// - Parameter x: 手势x偏移量
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
    
    /// 滑动到下一个视图
    private func p_nextScroll() {
        // 获取下一个视图的index
        currentIndex = (currentIndex + 1) % totalNumber
        UIView.animate(withDuration: 0.3) { [self] in
            // 将左中右三个视图向左移动一个视图宽度，将右边视图显示出来
            leftView?.frame = CGRect(x: -contentWidth * 2.0, y: 0.0, width: contentWidth, height: contentHeight)
            centerView?.frame = CGRect(x: -contentWidth, y: 0.0, width: contentWidth, height: contentHeight)
            rightView?.frame = CGRect(x: 0.0, y: 0.0, width: contentWidth, height: contentHeight)
        } completion: { [self] finished in
            // 左边视图存在，则将其放入缓存数组，并移除
            if let backView = leftView {
                p_addToCache(cell: backView)
                backView.removeFromSuperview()
            }
            
            // 将之前的centerView赋值给leftView，rightView赋值给centerView（保持centerView为中间展示的视图）
            leftView = centerView
            centerView = rightView
            
            // 获取新的右边视图
            if let nextView = delegate?.yzx_unlimitedRotationView(view: self, index: (currentIndex + 1) % totalNumber) {
                rightView = nextView
                addSubview(nextView)
            }
            
            pageControl.currentPage = currentIndex
            
            // 重新设置各视图的frame（主要设置新获取的rightView）
            p_resetLayout()
            
            // 自动滑动开启，启动timer
            if timer == nil && isAutoScroll {
                p_createTimer()
            }
        }
    }
    
    /// 滑动到上一个试图
    private func p_backScroll() {
        // 获取上一个视图的index
        currentIndex = (currentIndex - 1 < 0 ? (totalNumber - 1) : (currentIndex - 1))
        UIView.animate(withDuration: 0.3) { [self] in
            // 将左中右三个视图向右移动一个视图宽度，将左边视图显示出来
            leftView?.frame = CGRect(x: 0.0, y: 0.0, width: contentWidth, height: contentHeight)
            centerView?.frame = CGRect(x: contentWidth, y: 0.0, width: contentWidth, height: contentHeight)
            rightView?.frame = CGRect(x: contentWidth * 2.0, y: 0.0, width: contentWidth, height: contentHeight)
        } completion: { [self] finished in
            // 右边视图存在，则将其放入缓存数组，并移除
            if let nextView = rightView {
                p_addToCache(cell: nextView)
                nextView.removeFromSuperview()
            }
            
            // 将之前的centerView赋值给rightView，leftView赋值给centerView（保持centerView为中间展示的视图）
            rightView = centerView
            centerView = leftView
            
            // 获取新的左边视图
            if let backView = delegate?.yzx_unlimitedRotationView(view: self, index: (currentIndex - 1 < 0 ? (totalNumber - 1) : (currentIndex - 1))) {
                leftView = backView
                addSubview(backView)
            }
            
            pageControl.currentPage = currentIndex
            
            // 重新设置各视图的frame（主要设置新获取的rightView）
            p_resetLayout()
            
            // 自动滑动开启，启动timer
            if timer == nil && isAutoScroll {
                p_createTimer()
            }
        }
    }
    
    /// 重置视图位置
    private func p_resetLayout() {
        leftView?.frame = CGRect(x: -contentWidth, y: 0.0, width: contentWidth, height: contentHeight)
        centerView?.frame = CGRect(x: 0.0, y: 0.0, width: contentWidth, height: contentHeight)
        rightView?.frame = CGRect(x: contentWidth, y: 0.0, width: contentWidth, height: contentHeight)
    }
    
    /// 添加视图缓存
    private func p_addToCache(cell: UITableViewCell) {
        if cacheCells.contains(where: { $0.reuseIdentifier == cell.reuseIdentifier }) {
            return
        }
        cacheCells.append(cell)
    }
    
    /// 启动timer
    private func p_createTimer() {
        p_resetLayout()
        
        if totalNumber == 0 {
            return
        }
        
        timer = Timer.scheduledTimer(timeInterval: autoScrollTimeInterval, target: self, selector: #selector(p_timer), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    /// 销毁timer
    private func p_releaseTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    /// timer事件
    @objc func p_timer() {
        p_nextScroll()
    }
    //MARK: - --------------------- 私有方法 END ---------------------
    
    //MARK: - 公用方法
    func dequeueReusableCell(withReuseIdentifier identifier: String) -> UITableViewCell? {
        if let index = cacheCells.firstIndex(where: { $0.reuseIdentifier == identifier }) {
            let cell = cacheCells[index]
            cacheCells.remove(at: index)
            return cell
        }
        return nil
    }
    //MARK: - --------------------- 公用方法 END ---------------------
}

/// 处理嵌套到ScrollView上出现手势冲突的问题
extension YZXUnlimitedRotationView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
