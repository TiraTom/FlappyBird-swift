//
//  ViewController.swift
//  FlappyBird
//
//  Created by masao on 2019/05/25.
//  Copyright © 2019 TiraTom. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let skView = self.view as! SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        
        let scene = GameScene(size:skView.frame.size)
        
        skView.presentScene(scene)
        
    }

    
    // ステータスバーを非表示にする
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    

}

