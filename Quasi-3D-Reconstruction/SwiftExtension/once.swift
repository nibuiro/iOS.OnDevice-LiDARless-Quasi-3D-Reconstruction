//
//  once.swift
//  Quasi-3D-Reconstruction
//
//  Created by user01 on 2023/09/19.
//

import Foundation

infix operator ~=: AssignmentPrecedence
prefix operator ~

struct once<T> {
    var value: T
    public var obtained: Bool = false
    
    init(_ value: T) {
        self.value = value
    }
    
    static func ~= (lhs: inout T, rhs: once<T>) {
        if !rhs.obtained { abort() }
        lhs = rhs.value
    }
    
    static func ~= (lhs: inout once<T>, rhs: T) {
        lhs.value = rhs
        lhs.obtained = true
    }
    
    static prefix func ~(operand: once<T>) -> T {
        if !operand.obtained { abort() }
        return operand.value
    }
}

