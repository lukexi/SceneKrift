//
//  OVRView.h
//  SceneKrift
//
//  Created by Luke Iannini on 8/23/14.
//  Copyright (c) 2014 tree. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import "OSX_Platform.h"
#import "OSX_Gamepad.h"

@interface OVRView : NSOpenGLView <NSWindowDelegate>

@property (assign) OVR::OvrPlatform::OSX::PlatformCore* Platform;
@property (assign) OVR::OvrPlatform::Application* App;
@property unsigned long Modifiers;

- (void)warpMouseToCenter;

+ (CGDirectDisplayID) displayFromScreen:(NSScreen*)s;

- (void)renderEyeView:(ovrEyeRenderDesc)eyeRenderDesc
           projection:(ovrMatrix4f)projection
                 pose:(ovrPosef)pose;

@end