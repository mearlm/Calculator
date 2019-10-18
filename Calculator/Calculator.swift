//
//  Calculator.swift
//  iRogue
//
//  Created by Michael McGhan on 6/3/18.
//  Copyright © 2018 MSQR Laboratories. All rights reserved.
//

import Foundation

// the calculator parses the expression, and uses data from the this or root attribution
// to evaluate numerical, boolean or string results.
// the results may be used to update the same or other properties,
// generate events, or signal the UI.

// e.g. quaff a restore-strength potion, the hero's strength is restored
// and the UI notified to display updated stats;
// strike a sleeping monster, the monster-awaken (event) is sent
// causing new actions to result (i.e. the monster strikes back)

enum CalculationError: LocalizedError {
    case emptyStackError
    case invalidBinaryOp(error: String)
    case invalidUnaryOp(error: String)
    case invalidCall(error: String)
    case divideByZero(error: String)
    
    public var errorDescription: String? {
        switch self {
        case .emptyStackError:
            return "empty stack"
        case .invalidBinaryOp(let error),
             .invalidUnaryOp(let error),
             .invalidCall(let error),
             .divideByZero(let error):
            return "error: \(error)"
        }
    }
}

public class Calculator {
    public static let TheCalculator = Calculator(root: nil, alias: nil)      // default calculator
    private static let rogueRand = RogueRand()
    public static var useRogueRand = false
    
    private let root : Attribution?             // access via root (rootAlias) keyword
    private let rootAlias: String
    private var this: Attribution? = nil        // access via "this" keyword
    
    public init(root: Attribution?, alias: String?) {
        self.root = root
        self.rootAlias = (nil == alias) ? "root" : alias!
    }
    
    // result: 0 to limit - 1
    public static func rand(_ limit: Int) -> Int {
        if useRogueRand {
            return rogueRand.rnd(range: limit)
        }
        return Int.random(in: 0..<limit)
    }

    private var dataStack = [Attributable]()

    public func calculate(for expression: String, with this: Attribution) throws -> Bool {
        self.this = this
        
        if let nodes = parse(expression) {
            // print(String(describing: nodes))
            try evaluate(nodes: nodes, flip: false)
            return true
        }
        
        return false
    }
    
    public func hasValue() -> Bool {
        return !dataStack.isEmpty
    }
    
    public func value() -> Attributable? {
        if (hasValue()) {
            return dataStack.popLast()
        }
        return nil
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
    
    func evaluate(nodes: [ExprNode], this: Attribution) throws {
        self.this = this
        try evaluate(nodes: nodes, flip: false)
    }

    private func evaluate(nodes: [ExprNode], flip: Bool) throws {
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
                
                let source = addr.getSource(rootAlias: self.rootAlias)
                switch (source) {
                case VariableNode.SOURCE.THIS:
                    push(self.this)
                case VariableNode.SOURCE.ROOT:
                    push(self.root)
                default:
                    break               // use current top-of-stack
                }
                
                if let addrNode = Address(addr.asParts(for: source)) {
                    push(addrNode)
                }
                // ToDo: else... what?
            case is NoOpNode:
                if flip {
                    try swap()
                }
                break                   // ignore -- placeholder for current top-of-stack element
            case is UnaryOpNode:
                let node = node as! UnaryOpNode

                // convert rhs into top item on stack
                try evaluate(nodes: [node.rhs], flip: false)

                switch node.op {
                case "@", "++", "--":
                    // read address from top-of-stack
                    guard let addr = try pop()?.asAddress(),
                        let args = try pop()?.asAttribution() else {
                        throw CalculationError.emptyStackError
                    }
                    
                    // retrieve the value stored in the address
                    guard let value = try addr.fetch(args: args) else {
                        throw AttributionError.missingAttribute(for: node.description)
                    }

                    // replace address on stack with value retrieved
                    // NB: can be an Attributable of any type ...
                    push(value)
                    
                    if ("@" == node.op) {
                        break               // done
                    }
                    // ... but only integer types work below here

                    push(1)
                    if ("++" == node.op) {
                        try sum()
                    }
                    else {
                        try swap()
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
                
                try evaluate(nodes: [node.rhs], flip: false)    // rhs is new second-top item on stack
                try evaluate(nodes: [node.lhs], flip: true)     // lhs is new top item on stack

                switch node.op {
                case "=":                    // assignment
                    guard let addr = try pop()?.asAddress(),
                        let args = try pop()?.asAttribution(),
                        let value = pop() else {
                            throw CalculationError.emptyStackError
                    }
                    try addr.store(value: value, args: args)
                case "+=", "-=", "*=", "/=":
                    guard let addr = try pop()?.asAddress(),
                        let args = try pop()?.asAttribution(),
                        var increment = try pop()?.asInt() else {
                            throw CalculationError.emptyStackError
                    }

                    guard let value = try addr.fetch(args: args)?.asInt() else {
                        throw AttributionError.missingAttribute(for: node.description)
                    }

                    switch node.op {
                    case "-=":
                        increment = -increment
                        fallthrough
                    case "+=":
                        try addr.store(value: Attribute(value + increment), args: args)
                    case "*=":
                        try addr.store(value: Attribute(value * increment), args: args)
                    case "/=":
                        try addr.store(value: Attribute(value / increment), args: args)
                    default:
                        throw CalculationError.invalidBinaryOp(error: node.description)
                    }
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
                    let lhs = NumberNode(value: try (pop()?.asInt())!)
                    let rhs = NumberNode(value: try (pop()?.asInt())!)
                    try evaluate(nodes: [UnaryOpNode(op: "!", rhs: BinaryOpNode(op: ">", lhs: lhs, rhs: rhs))], flip: false)
                case "==":
                    try equals()
                case ">=":
                    let lhs = NumberNode(value: try (pop()?.asInt())!)
                    let rhs = NumberNode(value: try (pop()?.asInt())!)
                    try evaluate(nodes: [UnaryOpNode(op: "!", rhs: BinaryOpNode(op: "<", lhs: lhs, rhs: rhs))], flip: false)
                case "!=":
                    let lhs = NumberNode(value: try (pop()?.asInt())!)
                    let rhs = NumberNode(value: try (pop()?.asInt())!)
                    try evaluate(nodes: [UnaryOpNode(op: "!", rhs: BinaryOpNode(op: "==", lhs: lhs, rhs: rhs))], flip: false)
                default:
                    throw CalculationError.invalidBinaryOp(error: node.description)
                }
            case is IfNode:
                try processIf(node: node as! IfNode)
            case is ForEachNode:
                try processForEach(node: node as! ForEachNode)
            case is CallNode:
                let node = node as! CallNode

                switch node.callee {
                case "dup":
                    try dup(flip: flip)
                case "drop":
                    try drop()
                case "min", "max":
                    for arg in node.arguments {
                        try evaluate(nodes: [arg], flip: false)
                    }
                    push(node.arguments.count)

                    if ("min" == node.callee) {
                        try compare(node: node)       // min(n1, n2, ...)
                    }
                    else {
                        try compare(node: node)      // max(n1, n2, ...)
                    }
                case "rand":
                    try evaluate(nodes: [node.arguments[0]], flip: false)    // limit
                    try rand()          // rand(limit)
                case "exists":
                    try evaluate(nodes: [node.arguments[0]], flip: false)    // address (incl. key)
                    guard let addr = try pop()?.asAddress(),
                        let args = try pop()?.asAttribution() else {
                        throw CalculationError.emptyStackError
                    }
                    push(try addr.exists(args: args))
                case "select":
                    try evaluate(nodes: [node.arguments[0]], flip: false)    // distribution
                    try select()
                case "signed":
                    try evaluate(nodes: [node.arguments[0]], flip: false)    // number
                    try signedNumber()
                case "describe":
                    try evaluate(nodes: [node.arguments[1]], flip: false)    // name
                    try evaluate(nodes: [node.arguments[0]], flip: true)    // count
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
    
    private func push<T: Equatable>(_ value: T) {
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
    
    private func dup(flip: Bool) throws {
        if flip {
            try swap()
        }
        guard let top = pop() else {
            throw CalculationError.emptyStackError
        }
        push(top)
        if flip {
            try swap()
        }
        push(top)
        if flip {
            try swap()
        }
    }
    
    private func drop() throws {
        guard let _ = pop() else {
            throw CalculationError.emptyStackError
        }
    }
    
    private func negate() throws {
        guard let value = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        push(-value)
    }
    
    private func sum() throws {
        guard let lval = try pop()?.asInt(),
            let rval = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        push(lval + rval)
    }
    
    private func difference() throws {
        guard let lval = try pop()?.asInt(),
            let rval = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        push(lval - rval)
    }
    
    private func product() throws {
        guard let lval = try pop()?.asInt(),
            let rval = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        push(lval * rval)
    }
    
    private func ratio() throws {
        guard let lval = try pop()?.asInt(),
            let rval = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        guard rval != 0 else {
            throw CalculationError.divideByZero(error: String(describing: lval))
        }
        push(lval / rval)
    }
    
    private func remainder() throws {
        guard let lval = try pop()?.asInt(),
            let rval = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        push(lval % rval)
    }

    private func compare(node: CallNode) throws {
        guard var count = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        
        if (0 >= count) {
            throw CalculationError.invalidCall(error: "min() missing arguments.")
        }
        guard var lval = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        count -= 1
        
        while (0 < count) {
            guard let rval = try pop()?.asInt() else {
                throw CalculationError.emptyStackError
            }
            if (("min" == node.callee && rval < lval) || ("max" == node.callee && lval < rval)) {
                lval = rval
            }
            count -= 1
        }
        push(lval)
    }
    
    private func rand() throws {
        guard let value = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        push(Calculator.rand(value))
    }

    private func equals() throws {
        guard let lval = try pop()?.asInt(),
            let rval = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        push(lval == rval)
    }
    
    private func less() throws {
        guard let lval = try pop()?.asInt(),
            let rval = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        push(lval < rval)
    }
    
    private func greater() throws {
        guard let lval = try pop()?.asInt(),
            let rval = try pop()?.asInt() else {
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
        guard let lval = try pop()?.asBool(),
            let rval = try pop()?.asBool() else {
            throw CalculationError.emptyStackError
        }
        push(lval && rval)
    }
    
    private func or() throws {
        guard let lval = try pop()?.asBool(),
            let rval = try pop()?.asBool() else {
            throw CalculationError.emptyStackError
        }
        push(lval || rval)
    }
    
    // select an index from a distribution
    private func select() throws {
        guard let value = try pop()?.asDistribution(of: Attribution.self) else {
            throw CalculationError.emptyStackError
        }
        push(value.select())
    }
    
    private func throwDice() throws{
        guard let value = try pop()?.asDice() else {
            throw CalculationError.emptyStackError
        }
        push(roll(count: value.count, sides: value.sides))
    }
    
    // not currently used
    private func concat() throws {
        guard let lval = try pop()?.asString(),
            let rval = try pop()?.asString() else {
            throw CalculationError.emptyStackError
        }
        push(lval + rval)
    }

    // not currently used
    private func join() throws {
        guard let delimiter = try pop()?.asString(),
            let lval = try pop()?.asString() else {
            throw CalculationError.emptyStackError
        }
        if let rval = try pop()?.asString() {
            push(lval + delimiter + rval)
        }
        else {
            push(lval)
        }
    }

    private func signedNumber() throws {
        guard let value = try pop()?.asInt() else {
            throw CalculationError.emptyStackError
        }
        // ToDo: optional signed zero: 0 vs +0
        push(String(format: "%@\(value)", (0 > value) ? "" : "+"))
    }

    // NB: description rules by variant (e.g. food, slime-mold)
    private let vowels: Set<String> = ["a", "e", "i", "o", "u"]

    // a/3 two-handed sword/s; an/2 amber ring/s; a/4 potion/s (of healing)
    private func describe() throws {
        guard let count = try pop()?.asInt(),
            let name = try pop()?.asString() else {
            throw CalculationError.emptyStackError
        }

        if (1 == count) {
            let prefix = String(name.lowercased().prefix(1))
            if (vowels.contains(prefix)) {
                push("an \(name)")
            }
            else {
                push("a \(name)")
            }
        }
        else {
            push("\(count) \(name)s")
        }
    }
    
    private func processIf(node: IfNode) throws {
        guard let value = try pop()?.asBool() else {
            throw CalculationError.emptyStackError
        }
        if (value) {
            try evaluate(nodes: node.thenClause, flip: false)
        }
        else if (!node.elseClause.isEmpty) {
            try evaluate(nodes: node.elseClause, flip: false)
        }
    }
    
    // ToDo: expand to operate on Distribution objects?
    private func processForEach(node: ForEachNode) throws {
        guard let addr = try pop()?.asAddress(),
            let args = try pop()?.asAttribution() else {
            throw CalculationError.emptyStackError
        }
        if let wrapper = try addr.fetch(args: args) {
            let collection = try wrapper.asContainer()
            for element in collection.things {
                push(element)       // SOURCE.LOCAL
                try evaluate(nodes: node.expression, flip: false)
            }
        }
//        if let collectionWrapper = try addr.fetch(args: args) {
//            let container = try collectionWrapper.asType(type(of: collectionWrapper.rawValue() as Any))
//            let name = node.element.name
//
//            for element in container {
//                args.add(for: name, value: element)
//                try evaluate(nodes: node.expression, args: args, flip: false)
//            }
//            args.remove(for: name)

            // ToDo: way ugly!
            // ... but I can't find any way to coerce the type on the stack to a Container/Collection
//            let mirror = Mirror(reflecting: collectionWrapper.rawValue())
//            let name = node.element.name
//
//            for child in mirror.children {
//                if (child.label == "things") {
//                    // ... although, this cast seems to work
//                    if let elements = child.value as? Array<Attribution> {
//                        for element in elements {
//                            args.add(for: name, value: element)
//                            try evaluate(nodes: node.expression, flip: false)
//                        }
//                        args.remove(for: name)
//                    }
//                    return
//                }
//            }
//        }
    }
}

private class RogueRand {
    private var seed: UInt32
    private let magic1: UInt32 = 11109
    private let magic2: UInt32 = 12849
    
    init() {
        let lowtime = Int32(time(nil));
        
        //#ifdef MASTER
        //    if (wizard && getenv("SEED") != NULL)
        var dnum: Int32
        if let val = getenv("SEED") {
            dnum = atoi(val);
        }
        else {
            dnum = lowtime + SYS_getpid;
        }
        
        seed = UInt32(dnum);
        srandom(seed);
    }
    
    private func RN() -> UInt32 {
        var result = seed.multipliedReportingOverflow(by: magic1)
        result = result.partialValue.addingReportingOverflow(magic2)
        seed = result.partialValue
        
        return (seed >> 16) & 0xffff
    }
    
    public func rnd(range: Int) -> Int {
        return range == 0 ? 0 : abs(Int(RN())) % range;
    }
}
