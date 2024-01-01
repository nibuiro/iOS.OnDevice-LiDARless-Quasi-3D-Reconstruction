//
//  QuasiSfM-LinearAlgebra.swift
//  Quasi-3D-Reconstruction
//
//  Created by user01 on 2023/09/26.
//

import Foundation
import simd

struct Point2<T> {
    var x: T
    var y: T
    
    init(_ x: T, _ y: T) {
        self.x = x
        self.y = y
    }
}


func calcPointAtTargetZOnTheLineThrough2Points(p0: SIMD3<Float>, p1: SIMD3<Float>, targetZ: Float) -> SIMD3<Float> {
    // XY平面
    let v = p1 - p0
    let t = (targetZ - p0.z) / v.z
    let x = p0.x + t * v.x
    let y = p0.y + t * v.y
    let point = SIMD3<Float>(x, y, targetZ)
    
    return point
}

func calcPointAtTargetXOnTheLineThroughPoint03(p0: SIMD3<Float>, v: SIMD3<Float>, targetX: Float) -> SIMD3<Float> {
    // YZ平面
    let t = (targetX - p0.x) / v.x
    let y = p0.y + t * v.y
    let z = p0.z + t * v.z
    let point = SIMD3<Float>(targetX, y, z)
    
    return point
}

func calcPointAtTargetYOnTheLineThroughPoint03(p0: SIMD3<Float>, v: SIMD3<Float>, targetY: Float) -> SIMD3<Float> {
    // XZ平面
    let t = (targetY - p0.y) / v.y
    let x = p0.x + t * v.x
    let z = p0.z + t * v.z
    let point = SIMD3<Float>(x, targetY, z)
    
    return point
}

func calcPointAtTargetZOnTheLineThroughPoint03(p0: SIMD3<Float>, v: SIMD3<Float>, targetZ: Float) -> SIMD3<Float> {
    // XY平面
    let t = (targetZ - p0.z) / v.z
    let x = p0.x + t * v.x
    let y = p0.y + t * v.y
    let point = SIMD3<Float>(x, y, targetZ)
    
    return point
}


func planeLineIntersection(n: SIMD3<Float>, a: SIMD3<Float>, p0: SIMD3<Float>, d: SIMD3<Float>) -> SIMD3<Float> {
    let nDotD = simd_dot(n, d)
    
    // normal vector and line are orthonal
    if nDotD == 0 {
        return SIMD3<Float>(0,0,0)
    }
    
    let t = simd_dot(n, a - p0) / nDotD
    
    let intersectionPoint = p0 + t * d
    
    return intersectionPoint
}


func calcPointToLineOrthogonalIntersectionPoint(d: SIMD3<Float>, A0: SIMD3<Float>, pointP: SIMD3<Float>) -> SIMD3<Float> {

    let v = pointP - A0
    // projection
    let proj_v_d = simd_dot(d, v) / length(d)**2 * d
    let footOfPerpendicular = A0 + proj_v_d
    
    return footOfPerpendicular
}

func calcPointToLineOrthogonalVector(d: SIMD3<Float>, A0: SIMD3<Float>, pointP: SIMD3<Float>) -> SIMD3<Float> {

    let v = pointP - A0
    // projection
    let proj_v_d = simd_dot(d, v) / pow(length(d),2) * d
    let footOfPerpendicular = A0 + proj_v_d
    let OrthogonalProjectedVector = footOfPerpendicular - pointP
    
    return OrthogonalProjectedVector
}

func calcIntersectionPointFromPointPairs2(A: Point2<Float>, B: Point2<Float>, C: Point2<Float>, D: Point2<Float>) -> Point2<Float>
{
    // 直線ABとCDの傾きとy切片を計算
    let m1 = (B.y - A.y) / (B.x - A.x)
    let b1 = A.y - m1 * A.x

    let m2 = (D.y - C.y) / (D.x - C.x)
    let b2 = C.y - m2 * C.x

    // 直線ABとCDの交点を計算
    let x_intersection = (b2 - b1) / (m1 - m2)
    let y_intersection = m1 * x_intersection + b1
    
    return Point2<Float>(x_intersection, y_intersection)
}
