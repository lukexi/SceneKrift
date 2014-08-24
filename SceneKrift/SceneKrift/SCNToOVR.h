//
//  SCNToOVR.h
//  SceneKrift
//
//  Created by Luke Iannini on 8/23/14.
//  Copyright (c) 2014 tree. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import "OVR_CAPI.h"


SCNMatrix4 SCNMatrix4FromOVRMatrix4f(ovrMatrix4f matrix4f);
SCNQuaternion SCNQuaternionFromOVRQuatf(ovrQuatf quatf);
SCNVector3 SCNVector3FromOVRVector3(ovrVector3f vec3f);