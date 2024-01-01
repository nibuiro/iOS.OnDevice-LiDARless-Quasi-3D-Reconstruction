//
//  operator.swift
//  Quasi-3D-Reconstruction
//
//  Created by user01 on 2023/09/13.
//

import Foundation
import simd

precedencegroup ExponentiationPrecedence {
  associativity: right
  higherThan: MultiplicationPrecedence
}

infix operator ** : ExponentiationPrecedence

func ** (_ base: Double, _ exp: Double) -> Double {
  return pow(base, exp)
}

func ** (_ base: Float, _ exp: Float) -> Float {
  return pow(base, exp)
}

func ** (_ base: simd_float3x3, _ exp: Int) -> simd_float3x3 {
    var ret = base
    for _ in 0..<(exp-1) {
        ret *= base
    }
    return ret
}
