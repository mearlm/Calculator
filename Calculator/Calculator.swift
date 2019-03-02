//
//  Calculator.swift
//  iRogue
//
//  Created by Michael McGhan on 6/3/18.
//  Copyright © 2018 MSQR Laboratories. All rights reserved.
//

import Foundation

// the calculator parses the expression, and uses data from the args
// to evaluate numerical, boolean or string results.
// the results may be used to update the same or other properties,
// generate events, or signal the UI.

// e.g. quaff a restore-strength potion, the hero's strength is restored
// and the UI notified to display updated stats;
// strike a sleeping monster, the monster-awaken (event) is sent
// causing new actions to result (i.e. the monster strikes back)

enum CalculationError: Error {
    case emptyStackError
    case invalidBinaryOp(error: String)
    case invalidUnaryOp(error: String)
    case invalidCall(error: String)
}

public class Calculator {
    // result: 0 to limit - 1
    public static func rand(_ limit: Int) -> Int {
        // ToDo: implement classic Rogue rand
        return Int(arc4random_uniform(UInt32(limit)))   // Swift 4.1 nonsense; ToDo: update to 4.2
    }

    private var dataStack = [Attributable]()

    public func calculate(for expression: String, with args: Attribution) throws -> Bool {
        if let nodes = parse(expression) {
            print(String(describing: nodes))
            try evaluate(nodes: nodes, args: args)
            return true
        }
        
        return false
    }

    func parse(_ expression: String) -> [ExprNode]? {
        let lexer = Lexer(input: expression)
        let tokens = lexer.tokenize()
        
        let parser = Parser(tokens: tokens)
        do {
            return try parser.parse()
        }
        catch {
            // ToDo: handle errors properly
            print(error)
        }
        return nil
    }

    func evaluate(nodes: [ExprNode], args: Attribution) throws {
        for node in nodes {
            switch node {
            case is NumberNode:
                let num = node as! NumberNode
                push(num.value)
            case is StringLiteralNode:
                let str = node as! StringLiteralNode
                push(str.value)
            case is DiceNode:
                let dice = node as! DiceNode
                push(dice.value)
                try throwDice()         // convert to dice-roll value (i.e. numeric value)
            case is BooleanNode:
                let bool = node as! BooleanNode
                push(bool.value)
            case is VariableNode:
                let addr = node as! VariableNode
                push(Address(addr.name))
            case is UnaryOpNode:
                let node = node as! UnaryOpNode

                // convert rhs into top item on stack
                try evaluate(nodes: [node.rhs], args: args)

                switch node.op {
                case "@", "++", "--":
                    // read address from top-of-stack
                    guard let addr = try pop()?.asAddress() else {
                        throw CalculationError.emptyStackError
                    }
                    
                    // retrieve the value stored in the address
                    guard let value = try addr.fetch(args: args) else {
                        throw AttributionError.missingAttribute(for: node.op)
                    }

                    // replace address on stack with value retrieved
                    push(Attribute(value))
                    
                    if ("@" == node.op) {
                        break               // done
                    }

                    push(Attribute(1))
                    if ("++" == node.op) {
                        try sum()
                    }
                    else {
                        try difference()
                    }
                    try addr.store(value: pop(), args: args)
                case "+":
                    continue
                case "-":
                    try negate()
                case "!":
                    try not()
                default:
                    throw CalculationError.invalidUnaryOp(error: node.description)
                }
            case is BinaryOpNode:
                let node = node as! BinaryOpNode
                
                try evaluate(nodes: [node.rhs], args: args)     // rhs is new second-top item on stack
                try evaluate(nodes: [node.lhs], args: args)     // lhs is new top item on stack

                switch node.op {
                case "=":                    // assignment
                    guard let addr = try pop()?.asAddress(),
                        let value = pop() else {
                            throw CalculationError.emptyStackError
                    }
                    try addr.store(value: value, args: args)
                case "+=", "-=":
                    guard let addr = try pop()?.asAddress(),
                        var increment = try pop()?.asInt() else {
                            throw CalculationError.emptyStackError
                    }

                    if ("-=" == (node.op)) {
                        increment = -increment
                    }
                    
                    guard let value = try addr.fetch(args: args)?.asInt() else {
                        throw AttributionError.missingAttribute(for: node.op)
                    }
                    try addr.store(value: Attribute(value + increment), args: args)
                case "+":
                    try sum()
                case "-":
                    try difference()
                case "*":
                    try product()
                case "/":
                    try ratio()
                case "%":
                    try remainder()
                case "<":
                    try less()
                case ">":
                    try greater()
                case "&&":
                    try and()
                case "||":
                    try or()
                case "<=":
                    try evaluate(nodes: [UnaryOpNode(op: "!", rhs: BinaryOpNode(op: ">", lhs: node.lhs, rhs: node.rhs))], args: args)
                case "==":
                    try equals()
                case ">=":
                    try evaluate(nodes: [UnaryOpNode(op: "!", rhs: BinaryOpNode(op: "<", lhs: node.lhs, rhs: node.rhs))], args: args)
                case "!=":
                    try evaluate(nodes: [UnaryOpNode(op: "!", rhs: BinaryOpNode(op: "==", lhs: node.lhs, rhs: node.rhs))], args: args)
                default:
                    throw CalculationError.invalidBinaryOp(error: node.description)
                }
            case is IfNode:
                try processIf(node: node as! IfNode, args: args)
            case is ForEachNode:
                try processForEach(node: node as! ForEachNode, args: args)
            case is CallNode:
                let node = node as! CallNode

                switch node.callee {
                case "min", "max":
                    for arg in node.arguments {
                        try evaluate(nodes: [arg], args: args)
                    }
                    push(node.arguments.count)

                    if ("min" == node.callee) {
                        try min()       // min(n1, n2, ...)
                    }
                    else {
                        try max()       // max(n1, n2, ...)
                    }
                case "rand":
                    try evaluate(nodes: [node.arguments[0]], args: args)    // limit
                    try rand()          // rand(limit)
                case "exists":
                    try evaluate(nodes: [node.arguments[1]], args: args)    // address (incl. key)
                    guard let addr = try pop()?.asAddress() else {
                        throw CalculationError.emptyStackError
                    }
                    push(try addr.exists(args: args))
                case "signed":
                    try evaluate(nodes: [node.arguments[0]], args: args)    // number
                    try signedNumber()
                case "describe":
                    try evaluate(nodes: [node.arguments[1]], args: args)    // name
                    try evaluate(nodes: [node.arguments[0]], args: args)    // count
                    try describe()      // describe(count, name)
                default:
                    throw CalculationError.invalidCall(error: node.description)
                }
            default:
                break
            }
        }
    }
    
    // dice roll
    private func roll(count: Int, sides: Int) -> Int {
        var result = 0
        for _ in 0..<count {
            result += Calculator.rand(sides) + 1
        }
        return result
    }
    
    // a Forth-like token processor
    private func push(_ value: Attributable) {
        self.dataStack.append(value)
    }
    
    private func push(_ value: Int) {
        self.push(Attribute(value))
    }
    
    private func push(_ value: Bool) {
        self.push(Attribute(value))
    }
    
    private func push(_ value: String) {
        self.push(Attribute(value))
    }

    private func push(_ value: Dice) {
        self.push(Attribute(value))
    }
    
    private func push(_ value: Address) {
        self.push(Attribute(value))
    }

    private func pop() -> Attributable? {
        if !self.dataStack.isEmpty {
            return self.dataStack.removeLast()
        }
        return nil
    }
    
    private func swap() throws {
        guard let last = pop(),
            let first = pop() else {
                throw CalculationError.emptyStackError
        }
        push(last)
        push(first)
    }
    
    private func dup() throws {
        guard let top = pop() else {
            throw CalculationError.emptyStackError
        }
        push(top)
        push(top)
    }
    
    private func negate() throws {
        guard let rval = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        push(-rval)
    }
    
    private func sum() throws {
        guard let rval = try pop()?.asInt(),
            let lval = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        push(lval + rval)
    }
    
    private func difference() throws {
        guard let rval = try pop()?.asInt(),
            let lval = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        push(lval - rval)
    }
    
    private func product() throws {
        guard let rval = try pop()?.asInt(),
            let lval = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        push(lval * rval)
    }
    
    private func ratio() throws {
        guard let rval = try pop()?.asInt(),
            let lval = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        push(lval / rval)
    }
    
    private func remainder() throws {
        guard let rval = try pop()?.asInt(),
            let lval = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        push(lval % rval)
    }

    private func min() throws {
        guard let rval = try pop()?.asInt(),
            let lval = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        push(lval > rval ? rval : lval)
    }
    
    private func max() throws {
        guard let rval = try pop()?.asInt(),
            let lval = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        push(lval < rval ? rval : lval)
    }
    
    private func rand() throws {
        guard let value = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        push(Calculator.rand(value))
    }

    private func equals() throws {
        guard let rval = try pop()?.asInt(),
            let lval = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        push(lval == rval)
    }
    
    private func less() throws {
        guard let rval = try pop()?.asInt(),
            let lval = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        push(lval < rval)
    }
    
    private func greater() throws {
        guard let rval = try pop()?.asInt(),
            let lval = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        push(lval > rval)
    }
    
    private func not() throws {
        guard let value = try pop()?.asBool() else {
            throw CalculationError.emptyStackError
        }
        push(!value)
    }
    
    private func and() throws {
        guard let rval = try pop()?.asBool(),
            let lval = try pop()?.asBool() else {
            throw CalculationError.emptyStackError
        }
        push(lval && rval)
    }
    
    private func or() throws {
        guard let rval = try pop()?.asBool(),
            let lval = try pop()?.asBool() else {
            throw CalculationError.emptyStackError
        }
        push(lval || rval)
    }
    
    // select an index from a distribution
    private func select() throws {
        guard let value = try pop()?.asDistribution(of: Attribution.self) else {
            throw CalculationError.emptyStackError
        }
        push(Attribute(value.select()))
    }
    
    private func throwDice() throws{
        guard let value = try pop()?.asDice() else {
            throw CalculationError.emptyStackError
        }
        push(roll(count: value.count, sides: value.sides))
    }
    
    private func concat() throws {
        guard let rval = try pop()?.asString(),
            let lval = try pop()?.asString() else {
            throw CalculationError.emptyStackError
        }
        push(lval + rval)
    }

    private func join() throws {
        guard let delimiter = try pop()?.asString(),
            let rval = try pop()?.asString() else {
            throw CalculationError.emptyStackError
        }
        if let lval = try pop()?.asString() {
            push(lval + delimiter + rval)
        }
        else {
            push(rval)
        }
    }

    private func signedNumber() throws {
        guard let value = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        push(String(format: "%@\(value)", (0 > value) ? "" : "+"))
    }

    // NB: description rules by variant (e.g. food, slime-mold)
    private let vowels: Set<String> = ["a", "e", "i", "o", "u"]

    // a/3 two-handed sword/s; an/2 amber ring/s; a/4 potion/s (of healing)
    private func describe() throws {
        guard let name = try pop()?.asString(),
            let count = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }

        if (1 == count) {
            let prefix = String(name.lowercased().prefix(1))
            if (vowels.contains(prefix)) {
                push("an \(name) ")
            }
            push("a \(name) ")
        }
        else {
            push("\(count) \(name)s")
        }
    }
    
    private func processIf(node: IfNode, args: Attribution) throws {
        guard let value = try pop()?.asBool() else {
            throw CalculationError.emptyStackError
        }
        if (value) {
            try evaluate(nodes: node.thenClause, args: args)
        }
        else if (!node.elseClause.isEmpty) {
            try evaluate(nodes: node.elseClause, args: args)
        }
    }
    
    private func processForEach(node: ForEachNode, args: Attribution) throws {
        guard let addr = try pop()?.asAddress() else {
            throw CalculationError.emptyStackError
        }
        guard let elements = try addr.fetch(args: args)?.asType(AnySequence<Attributed>.self) else {    // Container
            throw AttributionError.invalidDereference(error: addr.asString())
        }

        let it = elements.makeIterator()
        while let element = it.next() {
            try evaluate(nodes: node.expression, args: element.attributes)
        }
    }
}
