//
//  SIMD3.swift
//  Quasi-3D-Reconstruction
//
//  Created by user01 on 2023/09/03.
//

import simd

func simd_make_rotate3(x: Float, y: Float, z: Float) -> simd_float3x3
{
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
    
    return Rzyx.transpose
}

func simd_make_rotate3(angle: Float, axis: SIMD3<Float>) -> simd_float3x3
{
    let cosθ = cos(angle)
    let sinθ = sin(angle)
    let K = simd_make_cross_product_operator3(n: axis)
    let R = matrix_identity_float3x3 + sinθ * K + (1 - cosθ) * K**2
    return R
}

func simd_make_cross_product_operator3(n: SIMD3<Float>) -> simd_float3x3
{
    let K = simd_float3x3(SIMD3<Float>(0, n.x, -n.y),
                          SIMD3<Float>(-n.z, 0, n.x),
                          SIMD3<Float>(n.y, -n.x, 0))
    
    return K
}
