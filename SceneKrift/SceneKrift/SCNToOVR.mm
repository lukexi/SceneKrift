//
//  SCNToOVR.m
//  SceneKrift
//
//  Created by Luke Iannini on 8/23/14.
//  Copyright (c) 2014 tree. All rights reserved.
//

#import "SCNToOVR.h"

SCNMatrix4 SCNMatrix4FromOVRMatrix4f(ovrMatrix4f matrix4f) {
    SCNMatrix4 matrix;
    matrix.m11 = matrix4f.M[0][0];
    matrix.m12 = matrix4f.M[0][1];
    matrix.m13 = matrix4f.M[0][2];
    matrix.m14 = matrix4f.M[0][3];
    matrix.m21 = matrix4f.M[1][0];
    matrix.m22 = matrix4f.M[1][1];
    matrix.m23 = matrix4f.M[1][2];
    matrix.m24 = matrix4f.M[1][3];
    matrix.m31 = matrix4f.M[2][0];
    matrix.m32 = matrix4f.M[2][1];
    matrix.m33 = matrix4f.M[2][2];
    matrix.m34 = matrix4f.M[2][3];
    matrix.m41 = matrix4f.M[3][0];
    matrix.m42 = matrix4f.M[3][1];
    matrix.m43 = matrix4f.M[3][2];
    matrix.m44 = matrix4f.M[3][3];
    
    return matrix;
}

SCNQuaternion SCNQuaternionFromOVRQuatf(ovrQuatf quatf) {
    SCNQuaternion quaternion;
    quaternion.x = quatf.x;
    quaternion.y = quatf.y;
    quaternion.z = quatf.z;
    quaternion.w = quatf.w;
    return quaternion;
}

SCNVector3 SCNVector3FromOVRVector3(ovrVector3f vec3f) {
    SCNVector3 vector3;
    vector3.x = vec3f.x;
    vector3.y = vec3f.y;
    vector3.z = vec3f.z;
    return vector3;
}