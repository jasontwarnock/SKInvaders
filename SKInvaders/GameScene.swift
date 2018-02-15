/**
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import SpriteKit
import CoreMotion

class GameScene: SKScene {
  
  // Private GameScene Properties
    
    var tapQueue = [Int]()
    let motionManager = CMMotionManager()
  
  var contentCreated = false
    
    var invaderMovementDirection: InvaderMovementDirection = .right
    var timeOfLastMove: CFTimeInterval = 0.0
    let timePerMove: CFTimeInterval = 1.0
    
    enum BulletType {
        case shipFired
        case invaderFired
    }
    
    enum InvaderMovementDirection {
        case right
        case left
        case downThenRight
        case downThenLeft
        case none
    }
    
    enum InvaderType {
        case a
        case b
        case c
        
        static var size: CGSize {
            return CGSize(width: 24, height: 16)
        }
        
        static var name: String {
            return "invader"
        }
    }
    
    let kInvaderGridSpacing = CGSize(width: 12, height: 12)
    let kInvaderRowCount = 6
    let kInvaderColCount = 6
    
    let kShipSize = CGSize(width: 30, height: 16)
    let kShipName = "ship"
    
    let kScoreHudName = "scoreHud"
    let kHealthHudName = "healthHud"
    
    let kShipFiredBulletName = "shipFiredBullet"
    let kInvaderFiredBulletName = "invaderFiredBullet"
    let kBulletSize = CGSize(width: 4, height: 8)
  
  // Object Lifecycle Management
  
  // Scene Setup and Content Creation
  override func didMove(to view: SKView) {
    
    if (!self.contentCreated) {
      self.createContent()
      self.contentCreated = true
        motionManager.startAccelerometerUpdates()
    }
  }
  
  func createContent() {
    
    physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
    
    setupInvaders()
    setupShip()
    setupHud()
    
    // black space color
    self.backgroundColor = SKColor.black
  }
  
    func makeInvader(ofType invaderType: InvaderType) -> SKNode {
        var invaderColor: SKColor
        
        switch(invaderType) {
        case .a:
            invaderColor = SKColor.red
        case .b:
            invaderColor = SKColor.green
        case .c:
            invaderColor = SKColor.blue
        }
        
        let invader = SKSpriteNode(color: invaderColor, size: InvaderType.size)
        invader.name = InvaderType.name
        
        return invader
    }
    
    func setupInvaders() {
        let baseOrigin = CGPoint(x: size.width/3, y: size.height/2)
        
        for row in 0..<kInvaderRowCount {
            
            var invaderType: InvaderType
            
            if row % 3 == 0 {
                invaderType = .a
            } else if row % 3 == 1 {
                invaderType = .b
                } else {
                invaderType = .c
            }
        
        let invaderPositionY = CGFloat(row) * (InvaderType.size.height * 2) + baseOrigin.y
        
        var invaderPosition = CGPoint(x: baseOrigin.x, y: invaderPositionY)
        
        for _ in 1..<kInvaderColCount {
            let invader = makeInvader(ofType: invaderType)
            invader.position = invaderPosition
            
            addChild(invader)
            
            invaderPosition = CGPoint(x: invaderPosition.x + InvaderType.size.width + kInvaderGridSpacing.width, y: invaderPositionY)
            }
        }
    }
    
    func setupShip() {
        let ship = makeShip()
        
        ship.position = CGPoint(x: size.width/2.0, y: kShipSize.height/2.0)
        addChild(ship)
    }
    
    func makeShip() -> SKNode {
        let ship = SKSpriteNode(color: SKColor.green, size: kShipSize)
        ship.name = kShipName
        
        ship.physicsBody = SKPhysicsBody(rectangleOf: ship.frame.size)
        ship.physicsBody!.isDynamic = true
        ship.physicsBody!.affectedByGravity = false
        ship.physicsBody!.mass = 0.2
        
        return ship
    }
    
    func setupHud() {
        let scoreLabel = SKLabelNode(fontNamed: "Courier")
        scoreLabel.name = kScoreHudName
        scoreLabel.fontSize = 25
        
        scoreLabel.fontColor = SKColor.green
        scoreLabel.text = String(format: "Score: %04u", 0)
        
        scoreLabel.position = CGPoint(x: frame.size.width/2, y: size.height - (40+scoreLabel.frame.size.height/2))
        addChild(scoreLabel)
        
        let healthLabel = SKLabelNode(fontNamed: "Courier")
        healthLabel.name = kHealthHudName
        healthLabel.fontSize = 25
        
        healthLabel.position = CGPoint(x: frame.size.width/2, y: size.height-(80+healthLabel.frame.size.height/2))
        addChild(healthLabel)
    }
    
    func makeBullet(ofType bulletType: BulletType) -> SKNode {
        var bullet: SKNode
        
        switch bulletType {
        case .shipFired:
            bullet = SKSpriteNode(color: SKColor.green, size: kBulletSize)
            bullet.name = kShipFiredBulletName
        case .invaderFired:
            bullet = SKSpriteNode(color: SKColor.magenta, size: kBulletSize)
            bullet.name = kInvaderFiredBulletName
            break
        }
        
        return bullet
    }
    
  // Scene Update
    
    func moveInvaders(forUpdate currentTime: CFTimeInterval) {
        if (currentTime - timeOfLastMove < timePerMove) {
            return
        }
        determineInvaderMovementDirection()
        
        enumerateChildNodes(withName: InvaderType.name) { node, stop in switch self.invaderMovementDirection {
        case .right:
            node.position = CGPoint(x: node.position.x + 10, y: node.position.y)
        case .left:
            node.position = CGPoint(x: node.position.x - 10, y: node.position.y)
        case .downThenLeft, .downThenRight:
            node.position = CGPoint(x: node.position.x, y: node.position.y - 10)
        case .none:
            break
        }
                
        self.timeOfLastMove = currentTime
        }
    }
    
    func processUserMotion(forUpdate currentTime: CFTimeInterval) {
        if let ship = childNode(withName: kShipName) as? SKSpriteNode {
            if let data = motionManager.accelerometerData {
                if fabs(data.acceleration.x) > 0.2 {
                    print("Acceleration: \(data.acceleration.x)")
                    ship.physicsBody!.applyForce(CGVector(dx: 40*CGFloat(data.acceleration.x), dy: 0))
                }
            }
        }
    }
  
  override func update(_ currentTime: TimeInterval) {
    /* Called before each frame is rendered */
    processUserMotion(forUpdate: currentTime)
    moveInvaders(forUpdate: currentTime)
  }
  
  // Scene Update Helpers
  
  // Invader Movement Helpers
    
    func determineInvaderMovementDirection() {
        var proposedMovementDirection: InvaderMovementDirection = invaderMovementDirection
        
        enumerateChildNodes(withName: InvaderType.name) {node, stop in switch self.invaderMovementDirection {
        case .right:
            if (node.frame.maxX >= node.scene!.size.width - 1.0) {
                proposedMovementDirection = .downThenLeft
                stop.pointee = true
            }
            
        case .left:
            if (node.frame.minX <= 1.0) {
                proposedMovementDirection = .downThenRight
                stop.pointee = true
            }
            
        case .downThenLeft:
            proposedMovementDirection = .left
            stop.pointee = true
            
        case .downThenRight:
            proposedMovementDirection = .right
            stop.pointee = true
            
        default:
            break
        }
    }
        if (proposedMovementDirection != invaderMovementDirection) {
            invaderMovementDirection = proposedMovementDirection
        }
    }
  
  // Bullet Helpers
  
  // User Tap Helpers
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if (touch.tapCount == 1) {
                tapQueue.append(1)
            }
        }
    }
  
  // HUD Helpers
  
  // Physics Contact Helpers
  
  // Game End Helpers
  
}
