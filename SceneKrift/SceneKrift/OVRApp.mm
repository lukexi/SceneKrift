//
//  OVRApp.m
//  SceneKrift
//
//  Created by Luke Iannini on 8/23/14.
//  Copyright (c) 2014 tree. All rights reserved.
//

#import "OVRApp.h"
#import "OVRView.h"
#import "OSX_Platform.h"
#import "OSX_Gamepad.h"

@implementation OVRApp

- (instancetype)initWithView:(OVRView *)view
{
    self = [super init];
    if (self) {
        self.view = view;
        OVR::OvrPlatform::Application* app;
        @autoreleasepool {
            {
                using namespace OVR;
                using namespace OVR::OvrPlatform;
                
                // CreateApplication must be the first call since it does OVR::System::Initialize.
                app = Application::CreateApplication();
                OSX::PlatformCore* platform = new OSX::PlatformCore(app, (void *)CFBridgingRetain(self));
                // The platform attached to an app will be deleted by DestroyApplication.
                app->SetPlatformCore(platform);
                
                [self setApp:app];
                [self setWin:view.window];
                [self setPlatform:platform];
                
                const char* argv[] = {"OVRApp"};
                int exitCode = app->OnStartup(1, argv);
                if (exitCode) {
                    Application::DestroyApplication(app);
                    exit(exitCode);
                }
            }
        }
    }
    return self;
}

- (void)run {
    [self idleLoop];
}

- (void)stop:(id)sender {
    
}

- (void)dealloc {
    OVR::OvrPlatform::Application::DestroyApplication(_App);
}

- (void)idleLoop {
    @autoreleasepool {
        _App->OnIdle();
    }
    [self performSelector:@selector(idleLoop) withObject:nil afterDelay:0];
}

@end