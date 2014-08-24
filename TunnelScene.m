//
//  TunnelScene.m
//  OculusWorldDemo
//
//  Created by Luke Iannini on 8/17/14.
//  Copyright (c) 2014 Oculus VR Inc. All rights reserved.
//

#import "TunnelScene.h"

CGFloat randFloat(CGFloat low, CGFloat high) {
    return low + arc4random_uniform(100000)/100000.0 * (high - low);
}

@implementation TunnelScene {
    CGPoint lastPoint;
    CGSize direction;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.physicsWorld.gravity = SCNVector3Make(0, 0, 0);
//    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(tunnelRing) userInfo:nil repeats:YES];
    [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(changeDirection) userInfo:nil repeats:YES];
    
    for (NSInteger i = 0; i < 500; i++) {
        [self tunnelRingOffset:-i];
    }
}

- (void)changeDirection {
//    direction = CGSizeMake(randFloat(-1,1)*2, randFloat(-1,1)*2);
}

- (void)tunnelRing {
    [self tunnelRingOffset:-100];
}

- (void)tunnelRingOffset:(CGFloat)offset {
    
    static CGFloat depth = 5;
    
    CGPoint newPoint = CGPointMake(lastPoint.x + direction.width, lastPoint.y + direction.height);
    lastPoint = newPoint;
    
    SCNNode *node = [SCNNode nodeWithGeometry:[SCNTube tubeWithInnerRadius:20
                                                               outerRadius:25
                                                                    height:depth]];
    node.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeDynamic shape:nil];
    node.geometry.firstMaterial = [SCNMaterial material];
    node.geometry.firstMaterial.diffuse.contents = [NSColor colorWithHue:arc4random_uniform(1000)/1000.0
                                                              saturation:0.5 brightness:1 alpha:1];
    node.rotation = SCNVector4Make(0, 1, 1, M_PI);
    node.position = SCNVector3Make(newPoint.x, newPoint.y, offset * depth);
    [self.rootNode addChildNode:node];
    
    node.physicsBody.velocity = SCNVector3Make(0, 0, 1000);
    node.physicsBody.damping = 0;
    
    SCNNode *lightNode = [SCNNode node];
    lightNode.position = SCNVector3Make(arc4random_uniform(20) - 10, arc4random_uniform(20) - 10, node.position.z);
    
    [self.rootNode addChildNode:lightNode];
    SCNLight *light = [SCNLight light];
    lightNode.light = light;
    
    light.type = SCNLightTypeOmni;
    light.attenuationEndDistance = 30;
    light.color = [NSColor colorWithHue:arc4random_uniform(1000)/1000.0 saturation:0.5 brightness:1 alpha:1];
}

@end
