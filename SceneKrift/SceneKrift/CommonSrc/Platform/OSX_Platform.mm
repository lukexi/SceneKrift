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
#import "TunnelScene.h"
#import "TestScene.h"
#import "SCNToOVR.h"

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

static int KeyMap[][2] = {
    { NSDeleteFunctionKey,      OVR::Key_Delete },
    { '\t',       OVR::Key_Tab },
    { '\n',    OVR::Key_Return },
    { NSPauseFunctionKey,     OVR::Key_Pause },
    { 27,      OVR::Key_Escape },
    { 127,     OVR::Key_Backspace },
    { ' ',     OVR::Key_Space },
    { NSPageUpFunctionKey,     OVR::Key_PageUp },
    { NSPageDownFunctionKey,      OVR::Key_PageDown },
    { NSNextFunctionKey,      OVR::Key_PageDown },
    { NSEndFunctionKey,       OVR::Key_End },
    { NSHomeFunctionKey,      OVR::Key_Home },
    { NSLeftArrowFunctionKey,      OVR::Key_Left },
    { NSUpArrowFunctionKey,        OVR::Key_Up },
    { NSRightArrowFunctionKey,     OVR::Key_Right },
    { NSDownArrowFunctionKey,      OVR::Key_Down },
    { NSInsertFunctionKey,    OVR::Key_Insert },
    { NSDeleteFunctionKey,    OVR::Key_Delete },
    { NSHelpFunctionKey,      OVR::Key_Insert },
};


static KeyCode MapToKeyCode(wchar_t vk) {
    unsigned key = Key_None;
    
    if ((vk >= 'a') && (vk <= 'z')) {
        key = vk - 'a' + Key_A;
    }
    else if ((vk >= ' ') && (vk <= '~')) {
        key = vk;
    }
    else if ((vk >= '0') && (vk <= '9')) {
        key = vk - '0' + Key_Num0;
    }
    else if ((vk >= NSF1FunctionKey) && (vk <= NSF15FunctionKey)) {
        key = vk - NSF1FunctionKey + Key_F1;
    }
    else {
        for (unsigned i = 0; i< (sizeof(KeyMap) / sizeof(KeyMap[1])); i++) {
            if (vk == KeyMap[i][0]) {
                key = KeyMap[i][1];
                break;
            }
        }
    }
    
    return (KeyCode)key;
}

static int MapModifiers(unsigned long xmod) {
    int mod = 0;
    if (xmod & NSShiftKeyMask)
        mod |= OVR::OvrPlatform::Mod_Shift;
    if (xmod & NSCommandKeyMask)
        mod |= OVR::OvrPlatform::Mod_Control;
    if (xmod & NSAlternateKeyMask)
        mod |= OVR::OvrPlatform::Mod_Alt;
    if (xmod & NSControlKeyMask)
        mod |= OVR::OvrPlatform::Mod_Meta;
    return mod;
}

@interface OVRView ()
@property (nonatomic, retain) SCNScene *scene;
@property (nonatomic, retain) SCNRenderer *leftRenderer;
@property (nonatomic, retain) SCNRenderer *rightRenderer;
@end

@implementation OVRView {

}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)ev {
    return YES;
}

+ (CGDirectDisplayID)displayFromScreen:(NSScreen *)s {
    NSNumber *didref = (NSNumber*)[[s deviceDescription] objectForKey:@"NSScreenNumber"];
    CGDirectDisplayID disp = (CGDirectDisplayID)[didref longValue];
    return disp;
}

- (void)warpMouseToCenter {
    NSRect r;
    r.origin.x = _Platform->Width/2.0f;
    r.origin.y = _Platform->Height/2.0f;
    NSPoint w = [[self window] convertRectToScreen:r].origin;
    CGDirectDisplayID disp = [OVRView displayFromScreen:[[self window] screen]];
    CGPoint p = {w.x, CGDisplayPixelsHigh(disp)-w.y};
    CGDisplayMoveCursorToPoint(disp, p);
}

static bool LookupKey(NSEvent* ev, wchar_t& ch, OVR::KeyCode& key, unsigned& mods) {
    NSString* chars = [ev charactersIgnoringModifiers];
    if ([chars length] == 0)
		return false;
	ch = [chars characterAtIndex:0];
    mods = MapModifiers([ev modifierFlags]);

	// check for Cmd+Latin Letter
    NSString* modchars = [ev characters];
    if ([modchars length]) {
        wchar_t modch = [modchars characterAtIndex:0];
		if (modch >= 'a' && modch <= 'z')
			ch = modch;
	}
	key = MapToKeyCode(ch);
    return true;
}

- (void)keyDown:(NSEvent*)ev {
	OVR::KeyCode key;
	unsigned     mods;
	wchar_t      ch;
	if (!LookupKey(ev, ch, key, mods))
		return;
    if (key == Key_Escape && _Platform->MMode == Mouse_Relative) {
        [self warpMouseToCenter];
        CGAssociateMouseAndMouseCursorPosition(true);
        [NSCursor unhide];
        _Platform->MMode = Mouse_RelativeEscaped;
    }
    _App->OnKey(key, ch, true, mods);
}

- (void)keyUp:(NSEvent*)ev {
	OVR::KeyCode key;
	unsigned     mods;
	wchar_t      ch;
	if (LookupKey(ev, ch, key, mods))
	    _App->OnKey(key, ch, false, mods);
}

static const OVR::KeyCode ModifierKeys[] = {
    OVR::Key_None, OVR::Key_Shift, OVR::Key_Control, OVR::Key_Alt, OVR::Key_Meta
};

- (void)flagsChanged:(NSEvent *)ev {
    unsigned long cmods = [ev modifierFlags];
    if ((cmods & 0xffff0000) != _Modifiers) {
        uint32_t mods = MapModifiers(cmods);
        for (int i = 1; i <= 4; i++) {
            unsigned long m = (1 << (16+i));
            if ((cmods & m) != (_Modifiers & m)) {
                if (cmods & m)
                    _App->OnKey(ModifierKeys[i], 0, true, mods);
                else
                    _App->OnKey(ModifierKeys[i], 0, false, mods);
            }
        }
        _Modifiers = cmods & 0xffff0000;
    }
}

- (void)ProcessMouse:(NSEvent*)ev {
    switch ([ev type]) {
        case NSLeftMouseDragged:
        case NSRightMouseDragged:
        case NSOtherMouseDragged:
        case NSMouseMoved: {
            if (_Platform->MMode == OVR::OvrPlatform::Mouse_Relative) {
                int dx = [ev deltaX];
                int dy = [ev deltaY];
                
                if (dx != 0 || dy != 0) {
                    _App->OnMouseMove(dx, dy, Mod_MouseRelative|MapModifiers([ev modifierFlags]));
                    [self warpMouseToCenter];
                }
            }
            else {
                NSPoint p = [ev locationInWindow];
                _App->OnMouseMove(p.x, p.y, MapModifiers([ev modifierFlags]));
            }
        }
        break;
        case NSLeftMouseDown:
        case NSRightMouseDown:
        case NSOtherMouseDown:
            break;
        default:
            break;
    }
}

- (void)mouseMoved:(NSEvent*)ev {
    [self ProcessMouse:ev];
}

- (void)mouseDragged:(NSEvent*)ev {
    [self ProcessMouse:ev];
}

- (void)mouseDown:(NSEvent*)ev {
    if (_Platform->MMode == Mouse_RelativeEscaped) {
        [self warpMouseToCenter];
        CGAssociateMouseAndMouseCursorPosition(false);
        [NSCursor hide];
        _Platform->MMode = Mouse_Relative;
    }
}

- (id)initWithFrame:(NSRect)frameRect {
    NSOpenGLPixelFormatAttribute attr[] = {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize, 24,
        NULL
    };
        
    NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attr];
    
    self = [super initWithFrame:frameRect pixelFormat:pf];
    GLint swap = 0;
    [[self openGLContext] setValues:&swap forParameter:NSOpenGLCPSwapInterval];
    //[self setWantsBestResolutionOpenGLSurface:YES];
    [self setupSceneKit];
    return self;
}

- (void)reshape {
    NSRect bounds = [self bounds];
    _App->OnResize(bounds.size.width, bounds.size.height);
    
    _Platform->Width = bounds.size.width;
    _Platform->Height = bounds.size.height;
    
    if (_Platform->GetRenderer()) {
        _Platform->GetRenderer()->SetWindowSize(bounds.size.width, bounds.size.height);

    }
}

- (BOOL)windowShouldClose:(id)sender {
    if (_Platform)
        _Platform->Exit(0);
    else
        exit(0);
    return 1;
}

// LXI
- (void)setupSceneKit {
    self.scene = [TestScene scene];
    self.leftRenderer = [SCNRenderer rendererWithContext:self.openGLContext.CGLContextObj options:nil];
    self.rightRenderer = [SCNRenderer rendererWithContext:self.openGLContext.CGLContextObj options:nil];
    self.leftRenderer.scene = self.scene;
    self.rightRenderer.scene = self.scene;
    // Causes all objects to be rendered black
    self.leftRenderer.autoenablesDefaultLighting = YES;
    self.rightRenderer.autoenablesDefaultLighting = YES;
    self.leftRenderer.pointOfView = [SCNNode node];
    self.rightRenderer.pointOfView = [SCNNode node];
    [self.scene.rootNode addChildNode:self.leftRenderer.pointOfView];
    [self.scene.rootNode addChildNode:self.rightRenderer.pointOfView];
    self.leftRenderer.pointOfView.camera = [SCNCamera camera];
    self.rightRenderer.pointOfView.camera = [SCNCamera camera];
    self.leftRenderer.pointOfView.camera.automaticallyAdjustsZRange = YES;
    self.rightRenderer.pointOfView.camera.automaticallyAdjustsZRange = YES;
    self.leftRenderer.pointOfView.position = SCNVector3Make(-1, 0, 0);
    self.rightRenderer.pointOfView.position = SCNVector3Make(1, 0, 0);
}

- (SCNRenderer *)rendererForEye:(ovrEyeType)eye {
    switch (eye) {
        case ovrEye_Left:
            return self.leftRenderer;
            break;
        case ovrEye_Right:
            return self.rightRenderer;
        default:
            break;
    }
    return nil;
}

- (void)renderEyeView:(ovrEyeRenderDesc)eyeRenderDesc
           projection:(Matrix4f)projection
                 pose:(ovrPosef)pose {
    OVR::FovPort fov = OVR::FovPort(eyeRenderDesc.Fov);
    
    SCNVector3 position = SCNVector3FromOVRVector3(pose.Position);
    position.x += eyeRenderDesc.ViewAdjust.x;
    position.y += eyeRenderDesc.ViewAdjust.y;
    position.z += eyeRenderDesc.ViewAdjust.z;
    
    position.x += eyeRenderDesc.Eye == ovrEye_Left ? -1 : 1;
    SCNRenderer *renderer = [self rendererForEye:eyeRenderDesc.Eye];
    renderer.pointOfView.orientation = SCNQuaternionFromOVRQuatf(pose.Orientation);
    renderer.pointOfView.position = position;
    renderer.pointOfView.camera.xFov = fov.GetHorizontalFovDegrees();
    renderer.pointOfView.camera.yFov = fov.GetVerticalFovDegrees();
    // Oops, this doesn't seem to be necessary! Gives weird distorted image.
    // Maybe because the projectionTransform is already set on the outside?
    //    renderer.pointOfView.camera.projectionTransform = SCNMatrix4Invert(SCNMatrix4FromMatrix4f(projection));
    [renderer render];
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

