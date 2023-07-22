//
//  GameScene.swift
//  Schoolhouse Skateboarder
//
//  Created by Maryna Bolotska on 21/07/23.
//

import SpriteKit
import GameplayKit

/// Эта структура содержит различные физические категории, и мы можем определить,
/// какие типы объектов сталкиваются или контактируют друг с другом
struct PhysicsCategory {
static let skater: UInt32 = 0x1 << 0
static let brick: UInt32 = 0x1 << 1
static let gem: UInt32 = 0x1 << 2
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var bricks = [SKSpriteNode]()
    var brickSize = CGSize.zero
    var scrollSpeed: CGFloat = 5.0
    let startingScrollSpeed: CGFloat = 5.0
    
    // Константа для гравитации (того, как быстро объекты падают на Землю)
    let gravitySpeed: CGFloat = 1.5
    
    // Время последнего вызова для метода обновления
    var lastUpdateTime: TimeInterval?
    
    
    let skater = Skater(imageNamed: "skater")
    
    override func didMove(to view: SKView) {
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -6.0)
        physicsWorld.contactDelegate = self
        
        anchorPoint = CGPoint.zero
        
        let background = SKSpriteNode(imageNamed: "background")
        let xMid = frame.midX
        let yMid = frame.midY
        background.position = CGPoint(x: xMid, y: yMid)
        addChild(background)
  
        
        skater.setupPhysicsBody()
        
        resetSkater()
        addChild(skater)
        
        let tapMethod = #selector(GameScene.handleTap(tapGesture:))
        let tapGesture = UITapGestureRecognizer(target: self, action: tapMethod)
        view.addGestureRecognizer(tapGesture)
        
       
        }
        
    func resetSkater() {
             // Задаем начальное положение скейтбордистки
              let skaterX = frame.midX / 2.0
             let skaterY = skater.frame.height / 2.0 + 64.0
             skater.position = CGPoint(x: skaterX, y: skaterY)
             skater.zPosition = 10
             skater.minimumY = skaterY
    }
    
    func updateSkater() {
        if !skater.isOnGround {
            // Устанавливаем новое значение скорости скейтбордистки с учетом влияния гравитации
            let velocityY = skater.velocity.y - gravitySpeed
            skater.velocity = CGPoint(x: skater.velocity.x, y: velocityY)
            // Устанавливаем новое положение скейтбордистки по оси y на основе ее скорости
            let newSkaterY: CGFloat = skater.position.y + 8
            skater.velocity.y
            skater.position = CGPoint(x: skater.position.x, y: newSkaterY)
            
            // Проверяем, приземлилась ли скейтбордистка
            if skater.position.y < skater.minimumY {
                skater.position.y = skater.minimumY
                skater.velocity = CGPoint.zero
                skater.isOnGround = true
            }
        }
       }
    

    func spawnBrick (atPosition position: CGPoint) -> SKSpriteNode {
    // Создаем спрайт секции и добавляем его к сцене
    let brick = SKSpriteNode(imageNamed: "sidewalk")
    brick.position = position
    brick.zPosition = 8
    addChild(brick)
    // Обновляем свойство brickSize реальным значением размера секции
    brickSize = brick.size
    // Добавляем новую секцию к массиву
    bricks.append(brick)
    // Возвращаем новую секцию вызывающему коду

        // Настройка физического тела секции
         let center = brick.centerRect.origin
         brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size,
        
                 center: center)
         brick.physicsBody?.affectedByGravity = false
        brick.physicsBody?.categoryBitMask = PhysicsCategory.brick
        brick.physicsBody?.collisionBitMask = 0
        
        return brick
    }
    
    func updateBricks(withScrollAmount currentScrollAmount: CGFloat) {
        var farthestRightBrickX: CGFloat = 0.0
        
        for brick in bricks {
                let newX = brick.position.x - currentScrollAmount
                 // Если секция сместилась слишком далеко влево
                  if newX < -brickSize.width {
                     brick.removeFromParent()
                      if let brickIndex = bricks.firstIndex(of: brick) {
                          bricks.remove(at: brickIndex)
                     }
         } else {
             // Для секции, оставшейся на экране, обновляем положение
                          brick.position = CGPoint(x: newX, y: brick.position.y)
                         //Обновляем значение для крайней правой секции
                      if brick.position.x > farthestRightBrickX {
                          farthestRightBrickX = brick.position.x
                         }
                     }
            }
        while farthestRightBrickX < frame.width {
         var brickX = farthestRightBrickX + brickSize.width + 1.0
        let brickY = brickSize.height / 2.0
            let randomNumber = arc4random_uniform(99)
            
            if randomNumber < 5 {
                         // 5-процентный шанс на то, что у нас
                         // возникнет разрыв между секциями
                          let gap = 20.0 * scrollSpeed
                          brickX += gap
                     }
            
            // Добавляем новую секцию и обновляем положение самой правой
                      let newBrick = spawnBrick(atPosition: CGPoint(x: brickX, y: brickY))
                      farthestRightBrickX = newBrick.position.x
            }
        }
            
    
    
    override func update(_ currentTime: TimeInterval) {
        // Определяем время, прошедшее с момента последнего вызова
         var elapsedTime: TimeInterval = 0.0
         if let lastTimeStamp = lastUpdateTime {
                  elapsedTime = currentTime - lastTimeStamp
        }
        lastUpdateTime = currentTime
        
        let expectedElapsedTime: TimeInterval = 1.0 / 60.0
        
        // Рассчитываем, насколько далеко должны сдвинуться объекты
        let scrollAdjustment = CGFloat(elapsedTime / expectedElapsedTime)
        let currentScrollAmount = scrollSpeed * scrollAdjustment
        
        updateBricks(withScrollAmount: currentScrollAmount)
        
        updateSkater()
    }
    
    @objc func handleTap(tapGesture: UITapGestureRecognizer) {
        // Заставляем скейтбордистку прыгнуть нажатием на экран, пока она находится на земле
        if skater.isOnGround {
                  skater.physicsBody?.applyImpulse(CGVector(dx: 0.0,
                     dy: 260.0))
        }
   }
   
    // MARK:- SKPhysicsContactDelegate Methods
     func didBegin(_ contact: SKPhysicsContact) {
    // Проверяем, есть ли контакт между скейтбордисткой и секцией
     if contact.bodyA.categoryBitMask == PhysicsCategory.skater &&
             contact.bodyB.categoryBitMask == PhysicsCategory.brick {
              skater.isOnGround = true
    }
    }
}


