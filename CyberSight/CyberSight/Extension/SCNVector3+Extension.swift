//
//  SCNVector3+Extension.swift
//  CyberSight
//
//  Created by Alfonso Tarallo on 01/04/24.
//

import SceneKit

extension SCNVector3 {
    func length() -> Float {
        return sqrtf(x * x + y * y + z * z)
    }
}

func -(l: SCNVector3, r: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(l.x - r.x, l.y - r.y, l.z - r.z)
}

func +(l: SCNVector3, r: SCNVector3) -> SCNVector3 {
    return SCNVector3(l.x + r.x, l.y + r.y, l.z + r.z)
}

func /(l: SCNVector3, r: Float) -> SCNVector3 {
    return SCNVector3(l.x / r, l.y / r, l.z / r)
}
