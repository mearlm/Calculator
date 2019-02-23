//
//  Nodes.swift
//  Kaleidoscope
//
//  Created by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//

import Foundation

protocol ExprNode: CustomStringConvertible {
}

// primitive types
struct StringLiteralNode: ExprNode {
    let value: String
    var description: String {
        return "StringLiteralNode(\(value))"
    }
}

struct NumberNode: ExprNode {
    let value: Int
    var description: String {
        return "NumberNode(\(value))"
    }
}

struct BooleanNode: ExprNode {
    var value: Bool
    var description: String {
        return "BooleanNode(\(value))"
    }
}

struct DiceNode: ExprNode {
    let value: Dice
    var description: String {
        return "DiceNode(\(value))"
    }
}

// variables (local attribute storage)
struct VariableNode: ExprNode {
    let name: String
    var description: String {
        return "VariableNode(\(name))"
    }
}

// operators
struct UnaryOpNode: ExprNode {
    let op: String
    let rhs: ExprNode
    var description: String {
        return "UnaryOpNode(\(op), rhs: \(rhs))"
    }
}

struct BinaryOpNode: ExprNode {
    let op: String
    let lhs: ExprNode
    let rhs: ExprNode
    var description: String {
        return "BinaryOpNode(\(op), lhs: \(lhs), rhs: \(rhs))"
    }
}

// built-in methods
struct CallNode: ExprNode {
    let callee: String
    let arguments: [ExprNode]
    var description: String {
        return "CallNode(name: \(callee), argument: \(arguments))"
    }
}

// if <top> then <thenClause> [else <elseClause>] endif
struct IfNode: ExprNode {
    let thenClause: [ExprNode]          // not empty
    let elseClause: [ExprNode]          // NB: can be empty
    var description: String {
        return "IfNode(if: \(thenClause), else \(elseClause)"
    }
}

protocol Builder {
    func build() throws -> ExprNode
    func addNode(nodes: [ExprNode], state: String) throws
}

class IfNodeBuilder : Builder {
    var thenClause: [ExprNode] = []
    var elseClause: [ExprNode] = []
    var nextState: String
    
    init() {
        nextState = "else"      // or endif
    }
    
    func addNode(nodes: [ExprNode], state: String) throws {
        switch (state) {
        case "else":
            guard state == nextState else {
                throw Errors.UnexpectedToken
            }
            thenClause = nodes
            nextState = "endif"
        case "endif":
            guard nextState == state || nextState == "else" else {
                throw Errors.UnexpectedToken
            }
            if ("else" == nextState) {
                thenClause = nodes
            }
            else if (!nodes.isEmpty) {
                elseClause = nodes
            }
            nextState = ""
        default:
            throw Errors.UnexpectedToken
        }
    }
    
    func build() throws -> ExprNode {
        guard !thenClause.isEmpty else {
            throw Errors.ExpectedExpression
        }
        return IfNode(thenClause: thenClause, elseClause: elseClause)
    }
}

// foreach <top.iterator.next> do <expression> loop
struct ForEachNode: ExprNode {
    let expression: [ExprNode]
    var description: String {
        return "ForEachNode(do: \(expression))"
    }
}

class ForEachNodeBuilder : Builder {
    var expression: [ExprNode]
    var nextState: String
    
    init() {
        expression = []
        nextState = "loop"
    }
    
    func addNode(nodes: [ExprNode], state: String) throws {
        switch (state) {
        case "loop":
            guard state == nextState,
                nodes.count > 0 else {
                    throw Errors.UnexpectedToken
            }
            expression = nodes
            nextState = ""
        default:
            throw Errors.UnexpectedToken
        }
    }
    
    func build() throws -> ExprNode {
        guard !expression.isEmpty else {
            throw Errors.ExpectedExpression
        }
        return ForEachNode(expression: expression)
    }
}

struct SubNode: ExprNode {
    let name: String
    var description: String {
        return "SubNode(name: \(name))"
    }
}

// extension methods
//struct PrototypeNode: CustomStringConvertible {
//    let name: String
//    let argumentNames: [String]
//    var description: String {
//        return "PrototypeNode(name: \(name), argumentNames: \(argumentNames))"
//    }
//}
//
//struct FunctionNode: CustomStringConvertible {
//    let prototype: PrototypeNode
//    let body: ExprNode
//    var description: String {
//        return "FunctionNode(prototype: \(prototype), body: \(body))"
//    }
//}
