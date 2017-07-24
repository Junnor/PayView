//
//  PayViewController.swift
//  PayView
//
//  Created by nyato on 2017/7/24.
//  Copyright © 2017年 nyato. All rights reserved.
//

import UIKit
import PassKit

enum PayType: String {
    case miaoPay = "喵币支付"
    case alipay = "支付宝支付"
    case wechatPay = "微信支付"
    case applePay = "Apple Pay"
    
    static let expectCount = 4
    
    static func pay(atItem item: Int) -> PayType {
        switch item {
        case 0: return .miaoPay
        case 1: return .alipay
        case 2: return .wechatPay
        default: return .applePay
        }
    }
    
    func imageForPay(_ type: PayType) -> UIImage {
        switch self {
        case .alipay: return #imageLiteral(resourceName: "pay-alipay")
        case .applePay: return #imageLiteral(resourceName: "pay-apple")
        case .wechatPay: return #imageLiteral(resourceName: "pay-wenxin")
        case .miaoPay: return #imageLiteral(resourceName: "pay-mcion")
        }
    }
}

protocol PayViewControllerDelegate: class {
    
    func payViewController(_ viewController: PayViewController, didSelectRowAt type: PayType)
    
}

class PayViewController: UIViewController {
    
    
    // MARK: - Public. for parent view controller
    
    weak var delegate: PayViewControllerDelegate?
    
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
    
    @objc private func dismissPayView() {
        self.shareShadowView.isHidden = true
        UIView.animate(withDuration: 0.2) {
            self.shareShadowView.backgroundColor = UIColor(white: 1, alpha: 0.0)
        }
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.view.frame.origin.y = self.view.superview!.frame.height
        }, completion: nil)
        
    }

    private var height: CGFloat {
        let promptHeight: CGFloat = 50
        let tableViewHeight: CGFloat = isApplePayAvailable() ? 4 * 61 : 3 * 61
        return promptHeight + tableViewHeight
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
            tableView.rowHeight = 61
            tableView.separatorStyle = .none
            tableView.register(UINib(nibName: "NormalPayCell", bundle: nil),
                               forCellReuseIdentifier: normalIdentifier)
            tableView.register(UINib(nibName: "ApplePayCell", bundle: nil),
                               forCellReuseIdentifier: appleIdentifier)

        }
    }
    
    
    fileprivate let normalIdentifier = "normal pay"
    fileprivate let appleIdentifier = "apple pay"
    
    private var addedToSuperView = false
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !addedToSuperView {
            addedToSuperView = true
            
            view.superview?.addSubview(shareShadowView)
            view.superview?.addSubview(view)
        }
    }
    
    @IBAction private func dismiss() {
        dismissPayView()
    }
    
    fileprivate var addedPayButton = false
    fileprivate var payNetworks = [PKPaymentNetwork]()
}

extension PayViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isApplePayAvailable() ? PayType.expectCount : PayType.expectCount - 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cellId = normalIdentifier
        
        if isApplePayAvailable() && (indexPath.row == (PayType.expectCount - 1)) {
            cellId = appleIdentifier
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier:cellId, for: indexPath)
        cell.selectionStyle = .none
        if let cell = cell as? NormalPayCell {
            var image: UIImage
            var text: String
            if indexPath.row == 0 {
                image = PayType.miaoPay.imageForPay(.miaoPay)
                text = PayType.miaoPay.rawValue
            } else if indexPath.row == 1 {
                image = PayType.alipay.imageForPay(.alipay)
                text = PayType.alipay.rawValue
            } else {
                image = PayType.wechatPay.imageForPay(.wechatPay)
                text = PayType.wechatPay.rawValue
            }
            
            cell.payImageView?.image = image
            cell.titleLabel?.text = text
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
            
            cell.titleLabel.text = PayType.applePay.rawValue
        }
        return cell
    }
    
    // MARK: - Helper
    
    fileprivate func isApplePayAvailable() -> Bool {
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
}


extension PayViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.payViewController(self, didSelectRowAt: PayType.pay(atItem: indexPath.item))
    }
}




