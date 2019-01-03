//
//  ViewController.swift
//  Demo
//
//  Created by eruYan on 2019/1/2.
//  Copyright © 2019 eruYan. All rights reserved.
//

import UIKit
import JYPhotoBrowser

class ViewController: UIViewController {

    @IBAction func buttonAction() {
        let vc = MainAssetGridViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }


}

