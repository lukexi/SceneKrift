//
//  TestScene.m
//  OculusWorldDemo
//
//  Created by Luke Iannini on 8/17/14.
//  Copyright (c) 2014 Oculus VR Inc. All rights reserved.
//

#import "TestScene.h"

@implementation TestScene

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    SCNNode *node = [SCNNode nodeWithGeometry:[SCNSphere sphereWithRadius:1]];
    node.position = SCNVector3Make(0, 0, -50);
    SCNMaterial *material = [SCNMaterial material];
    material.diffuse.contents = [NSColor redColor];
    material.locksAmbientWithDiffuse = YES;
    node.geometry.firstMaterial = material;
    [self.rootNode addChildNode:node];
    
    SCNAction *scale1 = [SCNAction scaleTo:2 duration:1];
    SCNAction *scale2 = [SCNAction scaleTo:1 duration:1];
    scale1.timingMode = SCNActionTimingModeEaseInEaseOut;
    scale2.timingMode = SCNActionTimingModeEaseInEaseOut;
    [node runAction:[SCNAction repeatActionForever:[SCNAction sequence:@[scale1, scale2]]]];
    
    SCNNode *big = [SCNNode nodeWithGeometry:[SCNSphere sphereWithRadius:20]];
    big.position = SCNVector3Make(0, 0, -100);
    big.geometry.firstMaterial = [SCNMaterial material];
    [self.rootNode addChildNode:big];
    
    
    SCNNode *huge = [SCNNode nodeWithGeometry:[SCNSphere sphereWithRadius:2000]];
    huge.position = SCNVector3Make(0, 0, -4000);
    huge.geometry.firstMaterial = [SCNMaterial material];
    [self.rootNode addChildNode:huge];
    
    SCNAction *move1 = [SCNAction moveTo:SCNVector3Make(-500, 0, -4000) duration:1];
    SCNAction *move2 = [SCNAction moveTo:SCNVector3Make(500, 0, -4000) duration:1];
    move1.timingMode = SCNActionTimingModeEaseInEaseOut;
    move2.timingMode = SCNActionTimingModeEaseInEaseOut;
    [huge runAction:[SCNAction repeatActionForever:[SCNAction sequence:@[move1, move2]]]];
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"contents"];
    anim.fromValue = [NSColor purpleColor];
    anim.toValue = [NSColor orangeColor];
    anim.autoreverses = YES;
    anim.repeatCount = MAXFLOAT;
    anim.duration = 5;
    [huge.geometry.firstMaterial addAnimation:anim forKey:nil];
    
    SCNNode *massive = [SCNNode nodeWithGeometry:[SCNSphere sphereWithRadius:10000]];
    massive.position = SCNVector3Make(15000, 0, 0);
    [self.rootNode addChildNode:massive];
    
    SCNNode *room = [SCNNode nodeWithGeometry:[SCNBox boxWithWidth:20000 height:20000 length:20000 chamferRadius:0]];
    room.geometry.firstMaterial = [SCNMaterial material];
    room.geometry.firstMaterial.doubleSided = YES;
    room.geometry.firstMaterial.diffuse.contents = [NSColor greenColor];
    [self.rootNode addChildNode:room];
    
    //    SCNNode *light = [SCNNode node];
    //    light.light = [SCNLight light];
    //    light.light.type = SCNLightTypeOmni;
    //    [self.scene.rootNode addChildNode:light];
}

@end
