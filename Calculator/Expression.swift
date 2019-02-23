//
//  Expression.swift
//  Calculator
//
//  Created by Michael McGhan on 7/4/18.
//  Copyright © 2018 MSQR Laboratories. All rights reserved.
//

import Foundation

protocol Expression {
    associatedtype T
    func evaluate() -> T
}

// a.k.a. predicate
class BooleanExpression : Expression {
    public func evaluate() -> Bool {
        return false
    }
}

class ArithmeticExpression : Expression {
    public func evaluate() -> Int {
        return 0
    }
}

class StringExpression : Expression {
    public func evaluate() -> String {
        return ""
    }
}
