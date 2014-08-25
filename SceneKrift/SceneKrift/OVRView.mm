//
//  OVRView.m
//  SceneKrift
//
//  Created by Luke Iannini on 8/23/14.
//  Copyright (c) 2014 tree. All rights reserved.
//

#import "OVRView.h"
#import "SCNToOVR.h"
#import "OVRApp.h"
#import "TunnelScene.h"
#import "TestScene.h"
#import "OSX_Platform.h"
#import "OSX_Gamepad.h"
using namespace OVR;
using namespace OVR::OvrPlatform;

@interface OVRView ()

@property (nonatomic, strong) SCNRenderer *leftRenderer;
@property (nonatomic, strong) SCNRenderer *rightRenderer;
@property (nonatomic, strong) OVRApp *ovrApp;

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



@implementation OVRView {
    
}

+ (CGDirectDisplayID)displayFromScreen:(NSScreen *)s {
    NSNumber *didref = (NSNumber*)[[s deviceDescription] objectForKey:@"NSScreenNumber"];
    CGDirectDisplayID disp = (CGDirectDisplayID)[didref longValue];
    return disp;
}

+ (NSOpenGLPixelFormat *)ovrPixelFormat {
    NSOpenGLPixelFormatAttribute attr[] = {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize, 24,
        NULL
    };
    
    return [[NSOpenGLPixelFormat alloc] initWithAttributes:attr];
}

- (void)awakeFromNib {
    [self setPixelFormat:[[self class] ovrPixelFormat]];
    [self commonInit];
}


- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect pixelFormat:[[self class] ovrPixelFormat]];
    if (self) {
//        [self commonInit];
    }
    return self;
}

static NSString *OVRHeadNodeName = @"OVRHeadNode";

- (void)commonInit {
    self.ovrApp = [[OVRApp alloc] initWithView:self];
    self.App = self.ovrApp.App;
    self.Platform = self.ovrApp.Platform;
    [self.ovrApp run];
    
    GLint swap = 0;
    [[self openGLContext] setValues:&swap forParameter:NSOpenGLCPSwapInterval];
    //[self setWantsBestResolutionOpenGLSurface:YES];
    
    self.leftRenderer = [SCNRenderer rendererWithContext:self.openGLContext.CGLContextObj
                                                 options:nil];
    self.rightRenderer = [SCNRenderer rendererWithContext:self.openGLContext.CGLContextObj
                                                  options:nil];
    self.leftRenderer.autoenablesDefaultLighting = YES;
    self.rightRenderer.autoenablesDefaultLighting = YES;
    
    self.headNode = [SCNNode node];
    self.headNode.name = OVRHeadNodeName;
    
    self.leftRenderer.pointOfView = [SCNNode node];
    self.rightRenderer.pointOfView = [SCNNode node];
    
    [self.headNode addChildNode:self.leftRenderer.pointOfView];
    [self.headNode addChildNode:self.rightRenderer.pointOfView];
    
    self.leftRenderer.pointOfView.camera = [SCNCamera camera];
    self.rightRenderer.pointOfView.camera = [SCNCamera camera];
    self.leftRenderer.pointOfView.camera.automaticallyAdjustsZRange = YES;
    self.rightRenderer.pointOfView.camera.automaticallyAdjustsZRange = YES;
    self.leftRenderer.pointOfView.position = SCNVector3Make(-1, 0, 0);
    self.rightRenderer.pointOfView.position = SCNVector3Make(1, 0, 0);
}

- (void)setScene:(SCNScene *)scene {
    _scene = scene;
    self.leftRenderer.scene = scene;
    self.rightRenderer.scene = scene;
    
    if (![scene.rootNode childNodeWithName:OVRHeadNodeName recursively:YES]) {
        [scene.rootNode addChildNode:self.headNode];
    }
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)ev {
    return YES;
}

- (void)warpMouseToCenter {
    NSRect r;
    r.origin.x = ((OVR::OvrPlatform::OSX::PlatformCore*) _Platform)->Width/2.0f;
    r.origin.y = ((OVR::OvrPlatform::OSX::PlatformCore*) _Platform)->Height/2.0f;
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
    if (!LookupKey(ev, ch, key, mods)) {
        return;
    }
    if (key == Key_Escape && ((OVR::OvrPlatform::OSX::PlatformCore*) _Platform)->MMode == Mouse_Relative) {
        [self warpMouseToCenter];
        CGAssociateMouseAndMouseCursorPosition(true);
        [NSCursor unhide];
        ((OVR::OvrPlatform::OSX::PlatformCore*) _Platform)->MMode = Mouse_RelativeEscaped;
    }
    ((OVR::OvrPlatform::Application*) _App)->OnKey(key, ch, true, mods);
}

- (void)keyUp:(NSEvent*)ev {
    OVR::KeyCode key;
    unsigned     mods;
    wchar_t      ch;
    if (LookupKey(ev, ch, key, mods)) {
        ((OVR::OvrPlatform::Application*) _App)->OnKey(key, ch, false, mods);
    }
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
                    ((OVR::OvrPlatform::Application*) _App)->OnKey(ModifierKeys[i], 0, true, mods);
                else
                    ((OVR::OvrPlatform::Application*) _App)->OnKey(ModifierKeys[i], 0, false, mods);
            }
        }
        _Modifiers = cmods & 0xffff0000;
    }
}

- (void)processMouse:(NSEvent*)ev {
    switch ([ev type]) {
        case NSLeftMouseDragged:
        case NSRightMouseDragged:
        case NSOtherMouseDragged:
        case NSMouseMoved: {
            if (((OVR::OvrPlatform::OSX::PlatformCore*) _Platform)->MMode == OVR::OvrPlatform::Mouse_Relative) {
                int dx = [ev deltaX];
                int dy = [ev deltaY];
                
                if (dx != 0 || dy != 0) {
                    ((OVR::OvrPlatform::Application*) _App)->OnMouseMove(dx, dy, Mod_MouseRelative|MapModifiers([ev modifierFlags]));
                    [self warpMouseToCenter];
                }
            }
            else {
                NSPoint p = [ev locationInWindow];
                ((OVR::OvrPlatform::Application*) _App)->OnMouseMove(p.x, p.y, MapModifiers([ev modifierFlags]));
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
    [self processMouse:ev];
}

- (void)mouseDragged:(NSEvent*)ev {
    [self processMouse:ev];
}

- (void)mouseDown:(NSEvent*)ev {
    if (((OVR::OvrPlatform::OSX::PlatformCore*) _Platform)->MMode == Mouse_RelativeEscaped) {
        [self warpMouseToCenter];
        CGAssociateMouseAndMouseCursorPosition(false);
        [NSCursor hide];
        ((OVR::OvrPlatform::OSX::PlatformCore*) _Platform)->MMode = Mouse_Relative;
    }
}



- (void)reshape {
    NSRect bounds = [self bounds];
    ((OVR::OvrPlatform::Application*) _App)->OnResize(bounds.size.width, bounds.size.height);
    
    ((OVR::OvrPlatform::OSX::PlatformCore*) _Platform)->Width = bounds.size.width;
    ((OVR::OvrPlatform::OSX::PlatformCore*) _Platform)->Height = bounds.size.height;
    
    if (((OVR::OvrPlatform::OSX::PlatformCore*) _Platform)->GetRenderer()) {
        ((OVR::OvrPlatform::OSX::PlatformCore*) _Platform)->GetRenderer()->SetWindowSize(bounds.size.width, bounds.size.height);
        
    }
}

- (BOOL)windowShouldClose:(id)sender {
    if (((OVR::OvrPlatform::OSX::PlatformCore*) _Platform)) {
        ((OVR::OvrPlatform::OSX::PlatformCore*) _Platform)->Exit(0);
    }
    else {
        exit(0);
    }
    return 1;
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
           projection:(ovrMatrix4f)projection
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