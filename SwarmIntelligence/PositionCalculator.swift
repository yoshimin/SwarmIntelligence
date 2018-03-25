//
//  Solver.swift
//  SwarmIntelligence
//
//  Created by Shingai Yoshimi on 2018/03/21.
//  Copyright © 2018年 Shingai Yoshimi. All rights reserved.
//

import UIKit
import Metal

struct PositionCalculator {
    private var device: MTLDevice? = MTLCreateSystemDefaultDevice()
    
    private var library: MTLLibrary?
    private var commandQueue: MTLCommandQueue?
    private var pipeline: MTLComputePipelineState?
    private var widthBuffer: MTLBuffer?
    private var heightBuffer: MTLBuffer?
    
    init(width: CGFloat, height: CGFloat) {
        guard let device = device else {
            return
        }
        
        commandQueue = device.makeCommandQueue()
        library = device.makeDefaultLibrary()
        if let function = library?.makeFunction(name: "move") {
            pipeline = try? device.makeComputePipelineState(function: function)
        }
        
        var w = Float(width)
        widthBuffer = device.makeBuffer(bytes: &w, length: MemoryLayout.size(ofValue: w), options: [])
        var h = Float(height)
        heightBuffer = device.makeBuffer(bytes: &h, length: MemoryLayout.size(ofValue: h), options: [])
        
    }
    
    func solve(objects: [Object], interval: Float) -> [Object] {
        guard let commandBuffer = commandQueue?.makeCommandBuffer(),
            let pipeline = pipeline,
            let encoder = commandBuffer.makeComputeCommandEncoder() else {
                return objects
        }
        
        encoder.setComputePipelineState(pipeline)
        
        guard let device = device, let outBuffer = device.makeBuffer(bytes: objects, length: objects.byteLength, options: []) else {
            return objects
        }
        
        let buffer = device.makeBuffer(bytes: objects, length: objects.byteLength, options: [])
        var count = UInt32(objects.count)
        let objectCountBuffer = device.makeBuffer(bytes: &count, length: MemoryLayout.size(ofValue: count), options: [])
        var interval = Float32(interval)
        let intervalBuffer = device.makeBuffer(bytes: &interval, length: MemoryLayout.size(ofValue: interval), options: [])
        
        encoder.setBuffer(buffer, offset: 0, index: 0)
        encoder.setBuffer(objectCountBuffer, offset: 0, index: 1)
        encoder.setBuffer(intervalBuffer, offset: 0, index: 2)
        encoder.setBuffer(widthBuffer, offset: 0, index: 3)
        encoder.setBuffer(heightBuffer, offset: 0, index: 4)
        encoder.setBuffer(outBuffer, offset: 0, index: 5)
        
        let groupsize = MTLSize(width: 64, height: 1, depth: 1)
        let numgroups = MTLSize(width: (objects.count + groupsize.width - 1) / groupsize.width, height: 1, depth: 1)
        
        encoder.dispatchThreadgroups(numgroups, threadsPerThreadgroup: groupsize)
        encoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        let data = Data(bytesNoCopy: outBuffer.contents(), count: objects.byteLength, deallocator: .none)
        var result = [Object](repeating: Object(positionX: 0, positionY: 0, velocityX: 0, velocityY: 0, angle: 0), count: objects.count)
        result = data.withUnsafeBytes {
            Array(UnsafeBufferPointer<Object>(start: $0, count: data.count/MemoryLayout<Object>.size))
        }
        
        return result
    }
}

struct Object {
    var positionX: Float = 0
    var positionY: Float = 0
    var velocityX: Float = 0
    var velocityY: Float = 0
    var angle: Float = 0
}

private extension Array {
    var byteLength: Int {
        return count * MemoryLayout.size(ofValue: self[0])
    }
}
