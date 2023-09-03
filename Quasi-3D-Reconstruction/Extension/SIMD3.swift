//
//  SIMD3.swift
//  Quasi-3D-Reconstruction
//
//  Created by user01 on 2023/09/03.
//

import simd

func simd_make_rotate3(x: Float, y: Float, z: Float) -> simd_float3x3 {
    let Rz = simd_float3x3(
        SIMD3<Float>(cos(z), sin(z), 0),
        SIMD3<Float>(-sin(z), cos(z), 0),
        SIMD3<Float>(0, 0, 1)
    )
    let Rx = simd_float3x3(
        SIMD3<Float>(1, 0, 0),
        SIMD3<Float>(0, cos(x), sin(x)),
        SIMD3<Float>(0, -sin(x), cos(x))
    )
    let Ry = simd_float3x3(
        SIMD3<Float>(cos(y), 0, -sin(y)),
        SIMD3<Float>(0, 1, 0),
        SIMD3<Float>(sin(y), 0, cos(y))
    )
    
    let Rzyx = Rz * Ry * Rx
    
    return Rzyx
}
