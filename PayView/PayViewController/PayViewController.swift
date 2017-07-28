//
//  PayViewController.swift
//  PayView
//
//  Created by nyato on 2017/7/24.
//  Copyright © 2017年 nyato. All rights reserved.
//
//
// If add new pay type to PayViewController..
// -------------------- Step: ------------------
// 1: add a new PayType case like: case applePay = "Apple Pay"
// 2: set value for public property height, add rowHeight for the giving pay type (if the pay type is availabel)
// 3: add the new pay type to private property items (in items initializer method)

import UIKit
import PassKit

enum PayType: String {
    case miaoPay = "喵币支付"
    case alipay = "支付宝支付"
    case wechatPay = "微信支付"
    case applePay = "Apple Pay"
    case qqPay = "QQ 支付"
}

protocol PayViewControllerDelegate: class {
    
    func payViewController(_ viewController: PayViewController, didSelectRowAt type: PayType)
    
}

class PayViewController: UIViewController {
    
    // MARK: - Public. for parent view controller
    
    weak var delegate: PayViewControllerDelegate?
    
    var height: CGFloat {
        // 高度设置不能直接使用 items.count * rowHeight, 
        // 因为此时 items.count = 0。 不能直接属性间的引用，除非被引用的属性是 let
        // https://stackoverflow.com/questions/7712325/cellforrowatindexpath-not-called
        let promptHeight: CGFloat = 50
        var tableViewHeight = 2 * rowHeight   // miaoPay, alipay
        
        if isWechatPayAvailable() {
            tableViewHeight += rowHeight
        }
        
        if isApplePayAvailable() {
            tableViewHeight += rowHeight
        }
        
        if isQQPayAvailable() {
            tableViewHeight += rowHeight
        }
        
        return promptHeight + tableViewHeight
    }
    
    @objc func showPayView() {
        self.shareShadowView.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.shareShadowView.backgroundColor = UIColor(white: 0, alpha: 0.4)
        }
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.view.frame.origin.y = self.view.superview!.frame.height - self.height
        }, completion: nil)
    }
    
    // MARK: - Private
    
    private let rowHeight: CGFloat = 61

    @objc private func dismissPayView() {
        self.shareShadowView.isHidden = true
        UIView.animate(withDuration: 0.2) {
            self.shareShadowView.backgroundColor = UIColor(white: 1, alpha: 0.0)
        }
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.view.frame.origin.y = self.view.superview!.frame.height
        }, completion: nil)
        
    }
    
    lazy private var shareShadowView: UIView = {
        let shadowView = UIView()
        shadowView.frame = UIScreen.main.bounds
        shadowView.backgroundColor = UIColor(white: 0, alpha: 0)
        shadowView.isHidden = true
        shadowView.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                               action: #selector(dismissPayView)))
        return shadowView
    }()
    
    @IBOutlet private weak var payLabel: UILabel!
    
    @IBOutlet private weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
            tableView.rowHeight = rowHeight
            tableView.separatorStyle = .none
            tableView.register(UINib(nibName: "NormalPayCell", bundle: nil),
                               forCellReuseIdentifier: normalPayIdentifier)
            tableView.register(UINib(nibName: "ApplePayCell", bundle: nil),
                               forCellReuseIdentifier: applePayIdentifier)
            
        }
    }
    
    
    fileprivate let normalPayIdentifier = "normal pay"
    fileprivate let applePayIdentifier = "apple pay"
    
    
    // MARK: - View controller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializerItems()
    }

    private var addedToSuperView = false
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !addedToSuperView {
            addedToSuperView = true
            
            view.superview?.addSubview(shareShadowView)
            view.superview?.addSubview(view)
        }
    }
    
    // MARK: Helper method
    
    @IBAction private func dismiss() {
        dismissPayView()
    }
    
    fileprivate var addedPayButton = false
    fileprivate var payNetworks = [PKPaymentNetwork]()
    
    fileprivate var items: [(index: Int, image: UIImage, payType: PayType)] = []
    private func initializerItems() {
        
        let miaoPay = (index: 0, image: #imageLiteral(resourceName: "pay-mcion"), payType: PayType.miaoPay)
        let alipay = (index: 1, image: #imageLiteral(resourceName: "pay-alipay"), payType: PayType.alipay)
        
        items.append(miaoPay)
        items.append(alipay)

        var next = 2
        
        var wechatPay: (index: Int, image: UIImage, payType: PayType)
        var applePay: (index: Int, image: UIImage, payType: PayType)
        var qqPay: (index: Int, image: UIImage, payType: PayType)

        if isWechatPayAvailable() {
            wechatPay = (index: next, image: #imageLiteral(resourceName: "pay-wenxin"), payType: PayType.wechatPay)
            next += 1
            items.append(wechatPay)
            
            if isApplePayAvailable() {
                applePay = (index: next, image: #imageLiteral(resourceName: "pay-apple"), payType: PayType.applePay)
                next += 1
                items.append(applePay)
            }
        }
        
        if !isWechatPayAvailable() && isApplePayAvailable() {
            applePay = (index: next, image: #imageLiteral(resourceName: "pay-apple"), payType: PayType.applePay)
            next += 1
            items.append(applePay)
        }
        
        // MARK: - test data for qq pay  .. test qq image
        if isQQPayAvailable() {
            qqPay = (index: next, image: #imageLiteral(resourceName: "pay-wenxin"), payType: PayType.qqPay)
            items.append(qqPay)
            next += 1
        }
    }
    
    // MARK: - Helper. type available check
    fileprivate func isApplePayAvailable() -> Bool {  // for apple pay
        var available = false
        
        // 需要银联
        if #available(iOS 9.2, *) {
            if PKPaymentAuthorizationViewController.canMakePayments() {
                payNetworks = [.chinaUnionPay]
                available = true
            }
        } else {
            // Fallback on earlier versions
        }
        
        return available
    }
    
    fileprivate func isWechatPayAvailable() -> Bool {   // for wechat pay
        let available = true
        
        return available
    }
    
    fileprivate func isQQPayAvailable() -> Bool {   // for qq pay
        let available = false
        
        return available
    }

}

extension PayViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]

        let cellId = item.payType == .applePay ? applePayIdentifier : normalPayIdentifier
        
        let cell = tableView.dequeueReusableCell(withIdentifier:cellId, for: indexPath)
        cell.selectionStyle = .none
        
        if let cell = cell as? NormalPayCell {
            cell.payImageView?.image = item.image
            cell.titleLabel?.text = item.payType.rawValue
        } else if let cell = cell as? ApplePayCell {
            if #available(iOS 8.3, *) {
                if !addedPayButton {
                    addedPayButton = true
                    
                    let payButton = PKPaymentButton(type: .plain, style: .whiteOutline)
                    
                    cell.applyPayView.backgroundColor = UIColor.clear
                    payButton.frame = cell.applyPayView.frame
                    cell.contentView.addSubview(payButton)
                }
                
            } else {
                // Fallback on earlier versions
            }
            
            cell.titleLabel.text = item.payType.rawValue
        }
        return cell
    }
}


extension PayViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        delegate?.payViewController(self, didSelectRowAt: item.payType)
    }
}




