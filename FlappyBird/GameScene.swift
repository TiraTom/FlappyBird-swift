//
//  GameScene.swift
//  FlappyBird
//
//  Created by masao on 2019/05/26.
//  Copyright © 2019 TiraTom. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode: SKNode!
    var wallNode: SKNode!
    var itemNode: SKNode!
    var bird: SKSpriteNode!
    
    // 衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0
    let groundCategory: UInt32 = 1 << 1
    let wallCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    let itemCategory: UInt32 = 1 << 4
    
    // スコア用変数
    var score = 0
    var itemScore = 0
    let userDefaults:UserDefaults = UserDefaults.standard
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    var itemScoreLabelNode:SKLabelNode!

    
    // SKView上にシーンが表示された時に呼ばれるメソッド
    override func didMove(to view: SKView){
        
        // 重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self
        
        // 背景色の設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        // スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        // 壁用のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        // アイテム用のノード
        itemNode = SKNode()
        scrollNode.addChild(itemNode)
        
        // シーンにスプライトを追加
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupItem()

        setupScoreLabel()
        
    }
    
    
    // スコアのセットアップ
    func setupScoreLabel() {
        
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = .black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100  // いちばん手前で表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "SCORE:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = .black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "BEST SCORE:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        itemScore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = .black
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        itemScoreLabelNode.zPosition = 100  // いちばん手前で表示する
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "ITEM SCORE:\(itemScore)"
        self.addChild(itemScoreLabelNode)
        
    }
    
    
    
    // アイテムのセットアップ
    func setupItem() {
        
        // アイテム三種類の画像を読み込む
        let itemInfo: [FlappyItem] = [FlappyItem("food_beef_stroganoff_rice", 35, 1),
                                      FlappyItem("food_oshiruko", 10, 2),
                                      FlappyItem("food_soboro_don", 5, 3)]
        
        // 出現アイテムを１つ選ぶ
        let selectedItem: FlappyItem = itemInfo[2]
        
        let itemTexture:SKTexture = selectedItem.itemImage
        
        // 当たり判定ありなので画質優先
        itemTexture.filteringMode = .linear
        
        // 移動距離を計算
        let movingDistance = CGFloat(self.frame.size.width + itemTexture.size().width)
        
        // 画面外まで移動する処理を作成
        let moveItem = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        
        // 自身を取り除く処理を作成
        let removeItem = SKAction.removeFromParent()
        
        // ２つのアニメーションを交互に行うアクションを作成
        let itemAnimation = SKAction.sequence([moveItem, removeItem])
        
        // アイテムの下限位置を決定
        let groundSize = SKTexture(imageNamed: "ground").size()
        let item_y_lowest = self.frame.size.height - groundSize.height * 2 - SKTexture(imageNamed: "bird_a").size().height * 2
        
        
        // 初めのアイテム作成までの時間待ちのアクション(壁と作成タイミングをずらす)
        let waitForWallAnimation = SKAction.wait(forDuration: 1)
        

        // アイテムを作成するアクション
        let createItemAnimation = SKAction.run({
            // アイテム用ノードの作成
            let item = SKNode()
            item.position = CGPoint(x: self.frame.size.width + itemTexture.size().width / 2, y:0)
            item.zPosition = -50   // 壁と同じ位置

            // アイテムのY座標をランダムに設定
            let item_y = CGFloat.random(in: 0..<item_y_lowest)
            
            // アイテム作成
            let itemSprite = SKSpriteNode(texture: itemTexture)
            let itemScale:CGSize = CGSize(width: SKTexture(imageNamed: "bird_a").size().width, height: SKTexture(imageNamed: "bird_a").size().height)
            itemSprite.scale(to: itemScale)
            itemSprite.position = CGPoint(x: 30, y: item_y)
            
            // アイテムに物理演算を設定
            itemSprite.physicsBody = SKPhysicsBody(circleOfRadius: itemSprite.frame.size.height / 2)
            
            // 衝突のカテゴリー設定
            itemSprite.physicsBody?.categoryBitMask = self.itemCategory
            itemSprite.physicsBody?.contactTestBitMask = self.birdCategory

            // 衝突の時には動かさせない
            itemSprite.physicsBody?.isDynamic = false
            item.addChild(itemSprite)
            item.run(itemAnimation)
            self.itemNode.addChild(item)
            
                
        })
        
        
        // 次のアイテム作成までの時間待ちのアクション
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // アイテム作成->時間待ち->アイテム作成　を繰り返すアクションの作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([waitForWallAnimation, createItemAnimation, waitAnimation]))

        itemNode.run(repeatForeverAnimation)
        
        
        
    }
    
    // 鳥の画像のセットアップ
    func setupBird() {
        // 鳥の画像を二種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        // 二種類のテクスチャを交互に変更するアニメーションを作成
        let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texturesAnimation)
        
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.width * 0.2, y: self.frame.size.height * 0.7)
        
        // 物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
        // 衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        // 衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
        
        // アニメーションを設定
        bird.run(flap)
        
        // スプライトを追加
        addChild(bird)
        
    }
    
    
    // 地面の画像のセットアップ
    func setupGround() {
        // 地面の画像の読み込み
        let groundTexture = SKTexture(imageNamed: "ground")
        // 画像が多少荒くなってでも処理速度を高める
        groundTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールをさせる
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y:0, duration: 5)
        // 元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y:0, duration: 0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        
        // groundのスプライトを配置する
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)
            
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )
            
            sprite.run(repeatScrollGround)
            
            // スプライトに物理演算を設定
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            // 衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            // 衝突の時に動かないようにする
            sprite.physicsBody?.isDynamic = false
            
            
            scrollNode.addChild(sprite)
        }

    }
    
    
    // 雲の画像のセットアップ
    func setupCloud() {
        // 雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせる
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y:0, duration: 20)
        
        // 元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        // 左にスクロール->元の位置->左にスクロール　を無限に繰り返す
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        // スプライトを配置
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100   // 一番後ろになるようにする
            
            // スプライトの表示する位置の指定
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            
            
            // スプライトにアニメーションを設定
            sprite.run(repeatScrollCloud)
            
            // スプライトの追加
            scrollNode.addChild(sprite)
        }
    }
    
    
    // 壁のセットアップ
    func setupWall(){
        
        // 壁画像の読み込み
        let wallTexture = SKTexture(imageNamed: "wall")
        // 当たり判定が入るので画質優先
        wallTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        // 画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y:0, duration: 4)
        
        // 自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        // ２つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        // 鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        // 鳥が通り抜ける隙間の長さを鳥のサイズの3.5倍とする
        let slit_length = birdSize.height * 3.5
        
        // 隙間位置の上下の振れ幅を鳥のサイズの３倍とする
        let random_y_range = birdSize.height * 3
        
        // 下の壁のY軸下限位置（中央位置から下方向の最大振れ幅で下の壁を表示する位置）を計算
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range / 2
        
        // 壁を生成するアクション生成
        let createWallAnimation = SKAction.run({
            // 壁関連のノードをのせるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50    // 雲より手前、地面より奥
            
            // 0~random_y_rangeまでのランダム地を生成
            let random_y = CGFloat.random(in: 0..<random_y_range)
            // Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = under_wall_lowest_y + random_y
            
            // 下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            // スプライトに物理演算を設定
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            // 衝突の時に動かないように設定する
            under.physicsBody?.isDynamic = false
            
            wall.addChild(under)
            
            
            
            // 上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            // スプライトに物理演算を設定
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            
            // 衝突の時に動かないように設定する
            upper.physicsBody?.isDynamic = false
            
            
            wall.addChild(upper)
            
            
            // スコアアップ用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x:upper.size.width + birdSize.width / 2, y:self.frame.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            wall.addChild(scoreNode)
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
            
        })
        
        //次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // 壁を作成->時間待ち-> 壁を作成　を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        wallNode.run(repeatForeverAnimation)
        
        
        
    }
    
    
    // SKPhysicsContactDelegateのメソッド。衝突した時に呼ばれる
    func didBegin(_ contact: SKPhysicsContact){
        // ゲームオーバーの時は何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            // スコア用の物体と衝突した
            print("ScoreUp")
            updateScore(type:PointUpType.GoThroughTunnel)

            
        }
        else if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory || (contact.bodyB.categoryBitMask & itemCategory) == itemCategory
        {
            // アイテムと衝突した
            print("ItemGet")
            updateScore(type:PointUpType.GetItem)
            
            // 音を鳴らす
            let soundIdRing:SystemSoundID = 1000  // new-mail.caf
            AudioServicesPlaySystemSound(soundIdRing)
            
            // アイテムを消す
            if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory {
                contact.bodyA.node?.removeFromParent()
                self.removeChildren(in: [contact.bodyA.node ?? SKNode()])
            } else {
                contact.bodyB.node?.removeFromParent()
                self.removeChildren(in: [contact.bodyB.node ?? SKNode()])
            }
        }
        else
        {
            // 壁か地面と衝突した
            print("GameOver")
            
            // スクロールを停止
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration: 1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
        }
        
    }
    
    
    // スコアの加算、ベストスコアの更新メソッド
    func updateScore(type:PointUpType) {
        
        if type == PointUpType.GoThroughTunnel
        {
            score += 1
            scoreLabelNode.text = "SCORE:\(score)"
            
            // ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "BEST SCORE:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
        }
        else if type == PointUpType.GetItem
        {
            itemScore += 1
            itemScoreLabelNode.text = "ITEM SCORE:\(itemScore)"
        }
    }
    
    
    // リスタート処理
    func restart() {
        score = 0
        scoreLabelNode.text = String("SCORE:\(score)")
        itemScore = 0
        itemScoreLabelNode.text = String("ITEM SCORE:\(score)")

        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        
        wallNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    
    // 画面をタップした場合に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        if scrollNode.speed > 0 {
            // 鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero
            
            // 鳥に縦方向の力を加える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
            
        } else if bird.speed == 0 {
            restart()
        }
    }

}

// ポイント加算アイテム
public class FlappyItem {
    var itemImage: SKTexture! = nil
    var appearPosibility: Double! = 0
    var scorePoint: Int! = 0
    
    init(_ imageName:String, _ posibility: Double, _ score: Int){
        self.itemImage = SKTexture(imageNamed: imageName)
        self.appearPosibility = posibility
        self.scorePoint = score
    }
}


// ポイントを獲得する方法
public enum PointUpType {
    case GoThroughTunnel
    case GetItem
}
