//
//  ViewController.swift
//  SwarmIntelligence
//
//  Created by Shingai Yoshimi on 2018/03/21.
//  Copyright © 2018年 Shingai Yoshimi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    fileprivate let count = 200
    
    fileprivate var displayLink:CADisplayLink!
    fileprivate var dots:[Dot] = []
    fileprivate var objects:[Object] = []
    fileprivate var lastTimeStamp: CFTimeInterval = 0
    fileprivate var calculator: PositionCalculator?
    
    deinit {
        displayLink.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFireflies()
        setupDisplayLink()
    }
}

// MARK: - Private
extension ViewController {
    fileprivate func setupFireflies() {
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        
        calculator = PositionCalculator(width: width, height: height)
        
        for _ in 0..<count {
            let x = arc4random_uniform(UInt32(width))
            let y = arc4random_uniform(UInt32(height))
            let vx = arc4random_uniform(UInt32(100))
            let vy = arc4random_uniform(UInt32(100))
            let angle = arc4random_uniform(360).radian
            
            let object = Object(positionX: Float(x), positionY: Float(y), velocityX: Float(vx)/100.0, velocityY: Float(vy)/100.0, angle: angle)
            objects.append(object)
            
            let dot = Dot()
            dot.update(with: object)
            self.view.addSubview(dot)
            dots.append(dot)
        }
        
        setupDisplayLink()
    }
    
    fileprivate func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.add(to: RunLoop.current, forMode: .defaultRunLoopMode)
    }
    
    @objc fileprivate func update() {
        if lastTimeStamp == 0 {
            lastTimeStamp = displayLink.timestamp
            return
        }
        
        let now = displayLink.timestamp
        let interval = now - lastTimeStamp
        lastTimeStamp = now
        
        guard let calculator = calculator else {
            return
        }
        
        objects = calculator.solve(objects: objects, interval: Float(interval))
        for (i, dot) in dots.enumerated() {
            dot.update(with: objects[i])
        }

    }
}

private extension UInt32 {
    var radian: Float {
        return Float(Double.pi / 180 * Double(self))
    }
}
