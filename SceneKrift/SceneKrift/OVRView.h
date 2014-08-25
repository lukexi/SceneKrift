//
//  OVRView.h
//  SceneKrift
//
//  Created by Luke Iannini on 8/23/14.
//  Copyright (c) 2014 tree. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import "OVR_CAPI.h"

@interface OVRView : NSOpenGLView <NSWindowDelegate>

@property (assign) void * Platform;
@property (assign) void * App;
@property unsigned long Modifiers;

@property (nonatomic, strong) SCNScene *scene;
@property (nonatomic, strong) SCNNode *headNode;

- (void)warpMouseToCenter;

+ (CGDirectDisplayID)displayFromScreen:(NSScreen*)s;

- (void)renderEyeView:(ovrEyeRenderDesc)eyeRenderDesc
           projection:(ovrMatrix4f)projection
                 pose:(ovrPosef)pose;

@end