//
//  Parser.swift
//  Kaleidoscope
//
//  Created by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//

import Foundation

enum Errors: Error {
    case UnexpectedToken
    case UndefinedOperator(String)
    
    case ExpectedCharacter(Character)
    case ExpectedExpression
    case ExpectedArgumentList
    case ExpectedFunctionName
    
    case ParseError(String)
}

class Parser {
    let tokens: [Token]
    private(set) var index = 0
    private var stack: [Builder] = []
    
    private static let _DEBUG = false
    
    init(tokens: [Token]) {
        self.tokens = tokens
        if Parser._DEBUG {
            for token in tokens {
                dprint("\(token)")
            }
        }
    }
    
    func hasNext() -> Bool {
        return self.index < self.tokens.count
    }
    
    func peekCurrentToken() -> Token? {
        dprint("peeking @\(index)")
        return (hasNext()) ? self.tokens[self.index] : nil
    }
    
    func popCurrentToken() -> Token? {
        guard hasNext() else {
            return nil
        }
        let i = self.index
        self.index += 1
        dprint("popping @\(i): \(tokens[i])")
        return tokens[i]
    }
    
    func discardToken() {
        _ = popCurrentToken()
    }
    
    func parseNumber() throws -> ExprNode {
        dprint("parseNumber")
        guard let next = popCurrentToken(),
            case let Token.Number(value) = next else {
                throw Errors.UnexpectedToken
        }
        return NumberNode(value: value)
    }
    
    func parseBoolean() throws -> ExprNode {
        dprint("parseBoolean")
        guard let next = popCurrentToken(),
            case let Token.Boolean(value) = next else {
                throw Errors.UnexpectedToken
        }
        return BooleanNode(value: value == "true")
    }
    
    func parseLiteral() throws -> ExprNode {
        dprint("parseLiteral")
        guard let next = popCurrentToken(),
            case let Token.StringLiteral(value) = next else {
                throw Errors.UnexpectedToken
        }
        return StringLiteralNode(value: value.replacingOccurrences(of: "\"\"", with: "\""))
    }
    
    func parseExpression() throws -> ExprNode {
        dprint("parseExpression")
        let node = try parsePrimary()
        dprint("parseExpression node: \(node)")
        
        return try parseBinaryOp(node)
    }
    
    func parseParens() throws -> ExprNode {
        dprint("parseParens")
        guard Token.ParensOpen == popCurrentToken() else {
            throw Errors.ExpectedCharacter("(")
        }
        
        let exp = try parseExpression()
        dprint("expression: \(exp)")
        
        guard Token.ParensClose == popCurrentToken() else {
            throw Errors.ExpectedCharacter(")")
        }
        
        return exp
    }
    
    func parseDice() throws -> ExprNode {
        dprint("parseDice")
        guard case let Token.Dice(count, sides) = popCurrentToken()! else {
            throw Errors.UnexpectedToken
        }
        dprint("dice: \(count) x \(sides)")
        
        return DiceNode(value: Dice(count: count, sides: sides))
    }
    
    func parseIdentifier() throws -> ExprNode {
        dprint("parseIdentifier")
        guard case let Token.Identifier(name) = popCurrentToken()! else {
            throw Errors.UnexpectedToken
        }
        dprint("identifier: \(name)")
        
        guard Token.ParensOpen == peekCurrentToken() else {
            return VariableNode(name: name)
        }
        discardToken()
        
        dprint("continuing: call expression-node")
        
        var arguments = [ExprNode]()
        if Token.ParensClose == peekCurrentToken() {
            dprint("identifier: p-close ignored")
        }
        else {
            while true {
                let argument = try parseExpression()
                arguments.append(argument)
                
                if Token.ParensClose == peekCurrentToken() {
                    break
                }
                
                guard Token.Comma == popCurrentToken() else {
                    throw Errors.ExpectedArgumentList
                }
            }
        }
        
        _ = popCurrentToken()
        return CallNode(callee: name, arguments: arguments)
    }
    
    func parseSubNode() throws -> ExprNode {
        dprint("parseSubNode")
        guard case let Token.SubNode(name) = popCurrentToken()! else {
            throw Errors.UnexpectedToken
        }
        dprint("subnode: \(name)")
        
        return SubNode(name: name)
    }

    private func pushBuilder(builder: Builder) {
        stack.append(builder)
    }

    private func popBuilder() throws -> Builder {
        if stack.isEmpty {
            throw Errors.UnexpectedToken
        }
        return stack.removeLast()
    }

    private func getBuilder() throws -> Builder {
        guard let builder = stack.last else {
            throw Errors.UnexpectedToken
        }
        return builder
    }
    
    // if (boolean) then expressions... [else expressions...] endif
    func parseIfElse() throws -> ExprNode {
        dprint("parseIfElse")
        guard case let Token.IfElse(name) = popCurrentToken()! else {
            throw Errors.ParseError("expected if-then-else-endif")
        }
        dprint("if-else: \(name)")

        var subnodes = [ExprNode]()
        pushBuilder(builder: IfNodeBuilder())

        dprint("continuing: if expression-node")
        
        while (true) {
            let expr = try parseExpression()
            if expr is SubNode {
                let node = expr as! SubNode
                
                let builder = try getBuilder()
                guard builder is IfNodeBuilder else {
                    throw Errors.ParseError(String(describing: type(of: builder)))
                }
                try builder.addNode(nodes: subnodes, state: node.name)
                subnodes = []
                
                if ("endif" == node.name) {
                    return try popBuilder().build()
                }
            }
            else {
                subnodes.append(expr)
            }
        }
    }
    
    // foreach iterable do expressions... loop
    func parseForEach() throws -> ExprNode {
        dprint("parseForEach")
        guard case let Token.ForEach(name) = popCurrentToken()! else {
            throw Errors.ParseError("expected foreach-do-loop")
        }
        dprint("for-each: \(name)")
        
        var subnodes = [ExprNode]()
        pushBuilder(builder: ForEachNodeBuilder())
        
        dprint("continuing: foreach expression-node")
        
        while (true) {
            let expr = try parseExpression()
            if expr is SubNode {
                let node = expr as! SubNode
                
                let builder = try getBuilder()
                guard builder is ForEachNodeBuilder else {
                    throw Errors.ParseError(String(describing: type(of: builder)))
                }
                try builder.addNode(nodes: subnodes, state: node.name)
                subnodes = []
                
                if ("loop" == node.name) {
                    return try popBuilder().build()
                }
            }
            else {
                subnodes.append(expr)
            }
        }
    }

    func parsePrimary() throws -> ExprNode {
        dprint("parsePrimary")
        if let token = peekCurrentToken() {
            dprint("token: \(token)")
            
            switch (token) {
            case .Identifier:
                return try parseIdentifier()
            case .Number:
                return try parseNumber()
            case .ParensOpen:
                return try parseParens()
            case .UnaryOp:
                return try parseUnaryOp()
            case .Dice:
                return try parseDice()
            case .StringLiteral:
                return try parseLiteral()
            case .Boolean:
                return try parseBoolean()
            case .IfElse:
                return try parseIfElse()
            case .ForEach:
                return try parseForEach()
            case .SubNode:
                return try parseSubNode()
            default:
                break
            }
        }
        throw Errors.ExpectedExpression
    }

    // NB: only used with binary ops: "[=+\\-*/%<>] | && | \\|\\| | <= | == | >= | !=
    let operatorPrecedence: [String: Int] = [
        "=":    5,      // loose
        "||":   10,
        "&&":   12,
        "==":   14,
        "!=":   14,
        "<":    16,
        "<=":   16,
        ">":    16,
        ">=":   16,
        "+":    20,
        "-":    20,
        "*":    40,
        "/":    40,
        "%":    40,     // tight
    ]
    
    func getCurrentTokenPrecedence() throws -> Int {
        dprint("getCurrentTokenPrecedence")
        guard index < tokens.count else {
            return -1
        }
        
        guard case let Token.BinaryOp(op2) = peekCurrentToken()! else {
            return -1
        }
        dprint("op2  \(op2)")
        
        guard let precedence = operatorPrecedence[op2] else {
            throw Errors.UndefinedOperator(op2)
        }
        
        return precedence
    }
    
    func parseBinaryOp(_ node: ExprNode, exprPrecedence: Int = 0) throws -> ExprNode {
        dprint("parseBinaryOp")
        
        var lhs = node
        dprint("lhs: \(lhs)")
        
        while true {
            let tokenPrecedence = try getCurrentTokenPrecedence()
            dprint("token-precedence: \(tokenPrecedence), expr-precedence: \(exprPrecedence)")
            
            if tokenPrecedence < exprPrecedence {
                dprint("binary-op: \(lhs)")
                return lhs
            }
            dprint("continuing...")
            
            guard let next = popCurrentToken(),
                case let Token.BinaryOp(op) = next else {
                    throw Errors.UnexpectedToken
            }
            dprint("op: \(op)")
            
            var rhs = try parsePrimary()
            dprint("rhs: \(rhs)")
            
            let nextPrecedence = try getCurrentTokenPrecedence()
            dprint("next-precedence: \(nextPrecedence)")
            
            if tokenPrecedence < nextPrecedence {
                rhs = try parseBinaryOp(rhs, exprPrecedence: tokenPrecedence+1)
            }
            lhs = BinaryOpNode(op: op, lhs: lhs, rhs: rhs)
            dprint("lhs: \(lhs)")
        }
    }
    
    func parseUnaryOp() throws -> ExprNode {
        dprint("parseUnaryOp")
        
        guard let next = popCurrentToken(),
            case let Token.UnaryOp(op) = next else {
                throw Errors.UnexpectedToken
        }
        dprint("op: \(op)")
        
        let rhs = try parsePrimary()
        dprint("rhs: \(rhs)")
        
        return UnaryOpNode(op: op, rhs: rhs)
    }
    
//    func parsePrototype() throws -> PrototypeNode {
//        dprint("parsePrototype")
//        guard let next = popCurrentToken(),
//            case let Token.Identifier(name) = next else {
//                throw Errors.ExpectedFunctionName
//        }
//
//        guard Token.ParensOpen == popCurrentToken() else {
//            throw Errors.ExpectedCharacter("(")
//        }
//
//        var argumentNames = [String]()
//        while true {
//            if let another = peekCurrentToken(),
//                case let Token.Identifier(name) = another {
//                argumentNames.append(name)
//                discardToken()
//
//                // end of definition
//                if Token.ParensClose == peekCurrentToken() {
//                    discardToken()      // remove ")"
//                    break
//                }
//
//                // another argument
//                guard Token.Comma == popCurrentToken() else {
//                    throw Errors.ExpectedArgumentList
//                }
//            }
//            else {
//                throw Errors.ExpectedCharacter(")")
//            }
//        }
//
//        return PrototypeNode(name: name, argumentNames: argumentNames)
//    }
    
//    func parseDefinition() throws -> FunctionNode {
//        dprint("parseDefinition")
//        
//        discardToken()      // "def"
//        let prototype = try parsePrototype()
//        let body = try parseExpression()
//        return FunctionNode(prototype: prototype, body: body)
//    }
    
    //    func parseTopLevelExpr() throws -> FunctionNode {
    //        dprint("parseTopLevelExpr")
    //
    //        let prototype = PrototypeNode(name: "", argumentNames: [])
    //        let body = try parseExpression()
    //        return FunctionNode(prototype: prototype, body: body)
    //    }
    
    func parse() throws -> [ExprNode] {
        self.index = 0
        
        var nodes = [ExprNode]()
        while self.index < self.tokens.count {
            dprint("parse: \(self.index)")

//            switch peekCurrentToken()! {
//            case .Define:
//                let node = try parseDefinition()
//                nodes.append(node)
//            default:
//                let expr = try parseExpression()
//                nodes.append(expr)
//            }

            let expr = try parseExpression()
            nodes.append(expr)
        }
        if (!stack.isEmpty) {
            throw Errors.ParseError("unterminated expression: \(String(describing: stack.last.self))")
        }
        
        return nodes
    }
    
    private func dprint(_ expression: String) {
        if (Parser._DEBUG) {
            print(expression)
        }
    }
}
