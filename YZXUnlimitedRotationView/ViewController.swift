//
//  ViewController.swift
//  YZXUnlimitedRotationView
//
//  Created by yinxing on 2022/6/28.
//

import UIKit

class ViewController: UIViewController {

    private var dataSource: [UIColor] = [.yellow, .purple, .orange, .red, .blue, .green, .gray, .cyan, .magenta, .brown]
    
    private let kCellIdentify = "cell_identify"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let rotationView = YZXUnlimitedRotationView(frame: CGRect(x: 40.0, y: 150.0, width: UIScreen.main.bounds.size.width - 80.0, height: 200.0))
        rotationView.backgroundColor = .white
        rotationView.delegate = self
        rotationView.isShowPageControl = true
        rotationView.pageType = .left
        view.addSubview(rotationView)
    }
}

extension ViewController: YZXUnlimitedRotationViewDelegate {
    func yzx_unlimitedRotationNumbers(view: YZXUnlimitedRotationView) -> Int {
        return dataSource.count
    }
    
    func yzx_unlimitedRotationView(view: YZXUnlimitedRotationView, index: Int) -> UITableViewCell {
        var cell = view.dequeueReusableCell(withReuseIdentifier: kCellIdentify)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: kCellIdentify)
        }
        cell?.contentView.backgroundColor = dataSource[index]
        return cell!
    }
    
    func yzx_unlimitedRotationView(view: YZXUnlimitedRotationView, didSelectedIndex index: Int) {
        print("------------------ \(index), \(dataSource[index])")
    }
}

