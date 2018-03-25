//
//  Shaders.metal
//  GPUCalc1
//
//  Created by Yukinaga2 on 2016/10/03.
//  Copyright © 2016年 Yukinaga. All rights reserved.
//

// @see https://qiita.com/yuky_az/items/ce5920f28c08e743418b#_reference-cc4434da198d861bba61

#include <metal_stdlib>
using namespace metal;

constant float alpha = 0.025;
constant float beta = 0.2;
constant float gamma = 0.005;

constant float spaceRatio = 0.12;

struct Object {
    float positionX;
    float positionY;
    float velocityX;
    float velocityY;
    float angle;
};

static float getDistace(float x1, float y1, float x2, float y2) {
    float dx = x1-x2;
    float dy = y1-y2;
    return sqrt(dx*dx + dy*dy);
}

static float getRangedAngle(float angle) {
    if (angle > M_PI_F){
        angle -= 2 * M_PI_F;
    } else if (angle < -M_PI_F){
        angle += 2 * M_PI_F;
    }
    return angle;
}

kernel void move(const device Object *in [[ buffer(0) ]],
                 const device uint &count [[ buffer(1) ]],
                 const device float &interval [[ buffer(2) ]],
                 const device float &width [[ buffer(3) ]],
                 const device float &height [[ buffer(4) ]],
                 device Object *out [[ buffer(5) ]],
                 uint id [[ thread_position_in_grid ]]) {
    Object current = in[id];
    
    float a = width * spaceRatio;
    float b = 6.25 / a / a;
    float dAngle = 0;
    
    float vx = current.velocityX;
    float vy = current.velocityY;
    float velocity = sqrt(vx*vx + vy*vy);
    
    float outerSpace = width * 0.1;
    
    for (uint i=0; i<count; i++){
        if (i == id){
            continue;
        };
        
        Object obj = in[i];
        
        float distance = getDistace(obj.positionX, obj.positionY, current.positionX, current.positionY);
        
        float nearAngle = getRangedAngle(atan2(obj.positionX-current.positionX, obj.positionY-current.positionY) - current.angle);
        float farAngle = getRangedAngle(atan2(current.positionX-obj.positionX, current.positionY-obj.positionY) - current.angle);
        float attraction = exp(-b * (distance - a)*(distance - a));
        float repulsion = exp(-b * distance * distance);
        dAngle += alpha * (nearAngle*attraction + farAngle*repulsion)*interval;
        
        float parallelAngleDif = getRangedAngle(obj.angle - current.angle);
        dAngle += beta * parallelAngleDif * exp(-b * distance * distance) * interval;
        
        float v = sqrt(obj.velocityX*obj.velocityX + obj.velocityY*obj.velocityY);
        velocity += gamma * (v - velocity) * exp(-b * distance * distance);
    }
    
    float newAngle = getRangedAngle(current.angle + dAngle);
    vx = velocity * sin(newAngle);
    vy = velocity * cos(newAngle);
    
    float newX = current.positionX + vx;
    if (newX > (width + outerSpace)) {
        newX -= (width + outerSpace*2);
    }
    if (newX < -outerSpace) {
        newX += width + outerSpace*2;
    }
    
    float newY = current.positionY + vy;
    if (newY > height + outerSpace) {
        newY -= height + outerSpace*2;
    }
    if (newY < -outerSpace) {
        newY += height + outerSpace*2;
    }
    
    out[id].positionX = newX;
    out[id].positionY = newY;
    out[id].velocityX = vx;
    out[id].velocityY = vy;
    out[id].angle = newAngle;
}
