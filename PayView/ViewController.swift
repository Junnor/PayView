//
//  ViewController.swift
//  PayView
//
//  Created by nyato on 2017/7/24.
//  Copyright © 2017年 nyato. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configurePayViewController()
    }
    
    private var payViewController: PayViewController!
    private func configurePayViewController() {
        payViewController = PayViewController(nibName: "PayViewController", bundle: nil)
        payViewController.delegate = self
        self.addChildViewController(payViewController)
        let bounds = UIScreen.main.bounds
        let rect = CGRect(x: 0, y: bounds.height, width: bounds.width, height: 294)
        payViewController.view.frame = rect
        view.addSubview(payViewController.view)
        payViewController.didMove(toParentViewController: self)
    }

    @IBAction func pay() {
        payViewController.showPayView()
    }
}


extension ViewController: PayViewControllerDelegate {
    
    func payViewController(_ viewController: PayViewController, didSelectRowAt type: PayType) {
        print("type: \(type)")
    }
    
}





