//
//  Dot.swift
//  SwarmIntelligence
//
//  Created by Shingai Yoshimi on 2018/03/21.
//  Copyright © 2018年 Shingai Yoshimi. All rights reserved.
//

import UIKit

class Dot: UIView {
    convenience init() {
        let width = 10
        
        self.init(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: width)))
        layer.cornerRadius = CGFloat(width)*0.5
        
        backgroundColor = UIColor.orange
    }
    
    func update(with object: Object) {
        self.center = CGPoint(x: CGFloat(object.positionX), y: CGFloat(object.positionY))
        self.transform =  CGAffineTransform(rotationAngle: CGFloat(object.angle))
    }
}
