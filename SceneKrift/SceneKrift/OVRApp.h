//
//  OVRApp.h
//  SceneKrift
//
//  Created by Luke Iannini on 8/23/14.
//  Copyright (c) 2014 tree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "OSX_Platform.h"

#import <CoreGraphics/CoreGraphics.h>
#import <CoreGraphics/CGDirectDisplay.h>
@class OVRView;
@interface OVRApp : NSObject

- (instancetype)initWithView:(OVRView *)view;

@property (assign) NSWindow *win;
@property (assign) OVR::OvrPlatform::OSX::PlatformCore* Platform;
@property (assign) OVR::OvrPlatform::Application* App;
@property (nonatomic, weak) OVRView *view;
- (void)run;
- (void)stop:(id)sender;

@end

