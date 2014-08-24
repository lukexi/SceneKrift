/************************************************************************************

Filename    :   OSX_Platform.mm
Content     :   
Created     :   
Authors     :   

Copyright   :   Copyright 2012 Oculus, Inc. All Rights reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

************************************************************************************/

#import "../Platform/OSX_PlatformObjc.h"
#import <SceneKit/SceneKit.h>


#import "OVRView.h"

using namespace OVR;
using namespace OVR::OvrPlatform;



@implementation OVRApp

- (void)run {
    OVR::OvrPlatform::Application* app;
    @autoreleasepool {
        _running = YES;
        {
            using namespace OVR;
            using namespace OVR::OvrPlatform;
            
            // CreateApplication must be the first call since it does OVR::System::Initialize.
            app = Application::CreateApplication();
            OSX::PlatformCore* platform = new OSX::PlatformCore(app, (void *)CFBridgingRetain(self));
            // The platform attached to an app will be deleted by DestroyApplication.
            app->SetPlatformCore(platform);
            
            [self setApp:app];
            [self setPlatform:platform];
            
            const char* argv[] = {"OVRApp"};
            int exitCode = app->OnStartup(1, argv);
            if (exitCode) {
                Application::DestroyApplication(app);
                exit(exitCode);
            }
        }
        [self finishLaunching];
    }

    while ([self isRunning]) {
        @autoreleasepool {
            NSEvent* event = [self nextEventMatchingMask:NSAnyEventMask
                                               untilDate:nil
                                                  inMode:NSDefaultRunLoopMode
                                                 dequeue:YES];
            if (event) {
                [self sendEvent:event];
            }
            _App->OnIdle();
        }
    }
    OVR::OvrPlatform::Application::DestroyApplication(app);
}

@end



namespace OVR { namespace OvrPlatform { namespace OSX {

PlatformCore::PlatformCore(Application* app, void* nsapp)
    : OvrPlatform::PlatformCore(app), NsApp(nsapp), Win(NULL), View(NULL), Quit(0), MMode(Mouse_Normal)
{
    pGamepadManager = *new OSX::GamepadManager();
}
PlatformCore::~PlatformCore()
{
}
    
void PlatformCore::Exit(int exitcode)
{
    OVRApp* nsApp = (__bridge OVRApp*)NsApp;
    [nsApp stop:nil];
}
    
String PlatformCore::GetContentDirectory() const
{
    NSBundle* bundle = [NSBundle mainBundle];
    if (bundle)
        return String([[bundle bundlePath] UTF8String]) + "/Contents/Resources";
    else
        return ".";
}


void PlatformCore::SetMouseMode(MouseMode mm)
{
    if (mm == MMode)
        return;

    if (Win)
    {
        if (mm == Mouse_Relative)
        {
            [NSCursor hide];
            [(__bridge OVRView*)View warpMouseToCenter];
            CGAssociateMouseAndMouseCursorPosition(false);
        }
        else
        {
            if (MMode == Mouse_Relative)
            {
                CGAssociateMouseAndMouseCursorPosition(true);
                [NSCursor unhide];
                [(__bridge OVRView*)View warpMouseToCenter];
            }
        }
    }
    MMode = mm;
}


void PlatformCore::GetWindowSize(int* w, int* h) const
{
    *w = Width;
    *h = Height;
}
    
void* PlatformCore::SetupWindow(int w, int h)
{
    NSRect winrect;
    winrect.origin.x = 0;
    winrect.origin.y = 1000;
    winrect.size.width = w;
    winrect.size.height = h;
    NSWindow *win = [[NSWindow alloc] initWithContentRect:winrect
                                                styleMask:NSTitledWindowMask|NSClosableWindowMask
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
    
    OVRView *view = [[OVRView alloc] initWithFrame:winrect];
    [view setPlatform:this];
    [win setContentView:view];
    [win setAcceptsMouseMovedEvents:YES];
    [win setDelegate:view];
    [view setApp:pApp];
    Win = (void *)CFBridgingRetain(win);
    View = (void *)CFBridgingRetain(view);
    return (void *)[win windowNumber];
}
    
void PlatformCore::SetWindowTitle(const char* title)
{
    [((__bridge NSWindow*)Win) setTitle:[[NSString alloc] initWithBytes:title
                                                                 length:strlen(title)
                                                               encoding:NSUTF8StringEncoding]];
}
    
void PlatformCore::ShowWindow(bool show)
{
    if (show)
        [((__bridge NSWindow*)Win) makeKeyAndOrderFront:nil];
    else
        [((__bridge NSWindow*)Win) orderOut:nil];
}

void PlatformCore::DestroyWindow()
{
    [((__bridge NSWindow*)Win) close];
    Win = NULL;
}

RenderDevice* PlatformCore::SetupGraphics(const SetupGraphicsDeviceSet& setupGraphicsDesc,
                                          const char* type, const Render::RendererParams& rp)
{
    const SetupGraphicsDeviceSet* setupDesc = setupGraphicsDesc.PickSetupDevice(type);
    OVR_ASSERT(setupDesc);
        
    pRender = *setupDesc->pCreateDevice(rp, this);
    if (pRender) {
        pRender->SetWindowSize(Width, Height);
    }
    
    return pRender.GetPtr();
}
    
int PlatformCore::GetDisplayCount()
{
    return (int)[[NSScreen screens] count];
}

Render::DisplayId PlatformCore::GetDisplay(int i)
{
    NSScreen* s = (NSScreen*)[[NSScreen screens] objectAtIndex:i];
    return Render::DisplayId([OVRView displayFromScreen:s]);
}

bool PlatformCore::SetFullscreen(const Render::RendererParams& rp, int fullscreen)
{
    if (fullscreen == Render::Display_Window) {
        [(__bridge OVRView*)View exitFullScreenModeWithOptions:nil];
    }
    else {
        NSScreen* usescreen = [NSScreen mainScreen];
        NSArray* screens = [NSScreen screens];
        for (int i = 0; i < [screens count]; i++)
        {
            NSScreen* s = (NSScreen*)[screens objectAtIndex:i];
            CGDirectDisplayID disp = [OVRView displayFromScreen:s];

            if (disp == rp.Display.CgDisplayId)
                usescreen = s;
        }
        
        [(__bridge OVRView*)View enterFullScreenMode:usescreen withOptions:nil];
        [(__bridge NSWindow*)Win setInitialFirstResponder:(__bridge OVRView*)View];
        [(__bridge NSWindow*)Win makeFirstResponder:(__bridge OVRView*)View];
    }

    if (pRender) {
        pRender->SetFullscreen((Render::DisplayMode)fullscreen);
    }
    return 1;
}

// LXI
void PlatformCore::RenderEyeView(ovrEyeRenderDesc eyeRenderDesc, Matrix4f projection, ovrPosef pose) {
    [(__bridge OVRView*)View renderEyeView:eyeRenderDesc projection:projection pose:pose];
}
}}
// GL
namespace Render { namespace GL { namespace OSX {

ovrRenderAPIConfig RenderDevice::Get_ovrRenderAPIConfig() const
{
    ovrRenderAPIConfig result = ovrRenderAPIConfig();
    result.Header.API = ovrRenderAPI_OpenGL;
    result.Header.RTSize = Sizei(WindowWidth, WindowHeight);
    result.Header.Multisample = Params.Multisample;
    return result;
}

Render::RenderDevice* RenderDevice::CreateDevice(const RendererParams& rp, void* oswnd)
{
    OvrPlatform::OSX::PlatformCore* PC = (OvrPlatform::OSX::PlatformCore*)oswnd;

    OVRView* view = (__bridge OVRView*)PC->View;
    NSOpenGLContext *context = [view openGLContext];
    if (!context)
        return NULL;

    [context makeCurrentContext];
    [((__bridge NSWindow*)PC->Win) makeKeyAndOrderFront:nil];

    return new Render::GL::OSX::RenderDevice(rp, (__bridge void*)context);
}

void RenderDevice::Present(bool useVsync)
{
    NSOpenGLContext *context = (__bridge NSOpenGLContext*)Context;
    [context flushBuffer];
}

void RenderDevice::Shutdown()
{
    Context = NULL;
}

bool RenderDevice::SetFullscreen(DisplayMode fullscreen)
{
    Params.Fullscreen = fullscreen;
    return 1;
}
    
}}}}


int main(int argc, char *argv[])
{
    NSApplication *nsapp = [OVRApp sharedApplication];
    [nsapp run];
    return 0;
}

