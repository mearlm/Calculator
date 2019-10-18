//
//  CalculatorTests.swift
//  CalculatorTests
//
//  Created by Michael McGhan on 6/17/18.
//  Copyright © 2018 MSQR Laboratories. All rights reserved.
//

import XCTest
@testable import Calculator

class CalculatorTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    private func testRand(maxcount: Int) {
        let limit = 100
        var maxval: (val: Int, at: Int) = (0, 0)
        var minval: (val: Int, at: Int) = (limit, 0)
        var allval = Array(repeating: 0, count: limit)
        
        var count = maxcount
        
        while (0 < count) {
            let rndval = Calculator.rand(limit)
            allval[rndval] += 1

            if (maxval.val < rndval) {
//                print("new maxval: \(rndval) was: \(maxval) at: \(count)")
                maxval = (rndval, count)
            }
            if (minval.val > rndval) {
//                print("new minval: \(rndval) was: \(minval) at: \(count)")
                minval = (rndval, count)
            }
            
            count -= 1
        }
        XCTAssert(maxval.val >= 0 && maxval.val < limit)
        XCTAssert(minval.val >= 0 && minval.val < limit)
        
        var maxAt: (count: Int, at: Int?) = (0, nil)
        var minAt: (count: Int, at: Int?) = (maxcount, nil)
        var missing: [Int] = []
        var distribution: [Int] = []
        
        for ix in 0..<limit {
            // print("@\(ix): \(allval[ix])")
            if 0 == allval[ix] {
                missing.append(ix)
            }
            else {
                if (maxAt.count < allval[ix]) {
                    maxAt = (allval[ix], ix)
                }
                if (minAt.count > allval[ix]) {
                    minAt = (allval[ix], ix)
                }
            }
            
            if (allval[ix] >= distribution.count) {
                // resize
                var d2 = Array(repeating: 0, count: allval[ix] + 1)
                for xi in 0..<distribution.count {
                    d2[xi] = distribution[xi]
                }
                distribution = d2
            }
            distribution[allval[ix]] += 1
        }
        
        // display stats
        print("max value: \(maxval) of \(maxcount)")
        print("min value: \(minval) of \(maxcount)")
        print("missing \(missing.count): \(missing) for isRogueRand: \(Calculator.useRogueRand)")
        print("max count: \(maxAt)")
        print("min count: \(minAt)")
        print("distribution: \(distribution)")
    }
    
    func testNewRand() {
        Calculator.useRogueRand = false
        testRand(maxcount: 400)
    }
    
    func testRogueRand() {
        Calculator.useRogueRand = true
        testRand(maxcount: 400)
    }

//    private func forEachExpressionParserTest(expression: String, count: Int) {
//        let calc = Calculator()
//        if let nodes = calc.parse(expression) {
//            XCTAssert(nodes.count == 1, expression)
//            guard case let node as ForEachNode = nodes.last else {
//                XCTAssert(false, expression)
//                return
//            }
//            XCTAssert(!node.expression.isEmpty, expression)
//            XCTAssert(node.expression.count == count, expression)
//        }
//        else if (0 <= count) {
//            XCTAssert(false, expression)
//        }
//        // parse failed (as expected)
//    }
//    
//    func testForEach() {
//        forEachExpressionParserTest(expression: "foreach thing loop", count: 1)
//        forEachExpressionParserTest(expression: "foreach thing and something more loop", count: 4)
//        forEachExpressionParserTest(expression: "foreach thing loop", count: -1)
//        forEachExpressionParserTest(expression: "foreach if a then b endif loop", count: 1)
//    }
//    
//    private func ifExpressionParserTest(expression: String, thenCount: Int, elseCount: Int) {
//        let calc = Calculator()
//        if let nodes = calc.parse(expression) {
//            XCTAssert(nodes.count == 1, expression)
//            guard case let node as IfNode = nodes.last else {
//                XCTAssert(false)
//                return
//            }
//            XCTAssert(!node.thenClause.isEmpty, expression)
//            XCTAssert(node.thenClause.count == thenCount, expression)
//            XCTAssert(node.elseClause.count == elseCount, expression)
//        }
//        else if (0 <= thenCount) {
//            XCTAssert(false, expression)
//        }
//        // parse failed (as expected)
//    }
//    
//    func testIfElse() {
//        ifExpressionParserTest(expression: "if a else b endif", thenCount: 1, elseCount: 1)
//        ifExpressionParserTest(expression: "if a endif", thenCount: 1, elseCount: 0)
//        ifExpressionParserTest(expression: "if zzz aaa mmm endif", thenCount: 3, elseCount: 0)
//        ifExpressionParserTest(expression: "if else c endif", thenCount: -1, elseCount: 0)
//        ifExpressionParserTest(expression: "if @a if c else d endif endif", thenCount: 1, elseCount: 0)
//        ifExpressionParserTest(expression: "if var if c endif else d endif", thenCount: 1, elseCount: 1)
//        ifExpressionParserTest(expression: "if foreach zzz do yyy loop endif", thenCount: 1, elseCount: 0)
//    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
    func testNodeCreate() {
        if let node: NumberNode = testSingleExpressionParse(expression: "666"),
            let actual : Int = testEvaluate(node: node) {
            XCTAssertEqual(actual, 666)
        }
        if let node: StringLiteralNode = testSingleExpressionParse(expression: "\"a 'string' \"\"literal\"\"\""),
            let actual : String = testEvaluate(node: node) {
            XCTAssertEqual(actual, "a 'string' \"literal\"")
        }
        if let node: DiceNode = testSingleExpressionParse(expression: "3d6"),
            let actual : Int = testEvaluate(node: node) {
            XCTAssert(actual >= 3 && actual <= 18)
        }
        if let node: BooleanNode = testSingleExpressionParse(expression: "true"),
            let actual: Bool = testEvaluate(node: node) {
            XCTAssertEqual(actual, true)
        }
        
        // addresses can refer to any (attribution) object
        let attr1 = Attribution()
        attr1.add(for: "xy", value: 132)
        let attr2 = Attribution()
        attr2.add(for: "xy", value: "acb")
        if let node: VariableNode = testSingleExpressionParse(expression: "xy"),
            let actual: Address = testEvaluate(node: node) {
            XCTAssertEqual(try! actual.fetch(args: attr1)?.asInt(), 132)
            XCTAssertEqual(try! actual.fetch(args: attr2)?.asString(), "acb")
        }
    }
    
    func testUnaryOps() {
        testUnaryOp("-0", expected: 0)
        testUnaryOp("-3", expected: -3)
        
        testUnaryOp("+0", expected: 0)
        testUnaryOp("+4", expected: 4)
        
        testUnaryOp("!true", expected: false)
        testUnaryOp("!false", expected: true)
    }
    
    func testAttrAssignment() {
        let attr = Attribution()
        assignmentTest(expression: "this.x = 3", attr: attr, actual: 3)     // assignment of missing attribute
        assignmentTest(expression: "this.x += 3", attr: attr, actual: 6)
        assignmentTest(expression: "this.x -= 8", attr: attr, actual: -2)
        assignmentTest(expression: "this.x *= -2", attr: attr, actual: 4)
        assignmentTest(expression: "this.x /= 4", attr: attr, actual: 1)
    }
    
    func testAttrIncrDecr() {
        let attr = Attribution()
        attr.add(for: "x", value: 3)
        
        // NB: x++, x-- NOT supported (lexer fails)
        testIncrDecr(expression: "++this.x", attr: attr, actual: 4)
        testIncrDecr(expression: "--this.x", attr: attr, actual: 3)
    }

    func testAttrFetch() {
        let attr = Attribution()
        attr.add(for: "x", value: 3)
        
        // NB: @<var> pulls the attribute's value onto the top of the stack
        testIncrDecr(expression: "@this.x", attr: attr, actual: 3)
        do {
            let top = try Calculator.TheCalculator.value()!.asType(Int.self)
            XCTAssertEqual(top, 3)
        }
        catch {
            print(error)
            XCTFail()
        }
        XCTAssert(!Calculator.TheCalculator.hasValue())          // stack is not empty
    }
    
    // except for assignment (=), an attribute must already be defined (and of the correct type)
    func testMissingAttributeError() {
        attrMissingError(expression: "@this.x", message: "UnaryOpNode(@, rhs: VariableNode(this.x))")
        attrMissingError(expression: "++this.x", message: "UnaryOpNode(++, rhs: VariableNode(this.x))")
        attrMissingError(expression: "this.x += 2", message: "BinaryOpNode(+=, lhs: VariableNode(this.x), rhs: NumberNode(2))")
    }
    
    func testAttrTypeError() {
        attrTypeError(expression: "++this.x", message: "invalid: For String, requested: Int.Type")
    }

    func testBinaryOps() {
        testBinaryOp("2 + 3", expected: 5)
        testBinaryOp("3 - 2", expected: 1)
        testBinaryOp("2 - 3", expected: -1)
        testBinaryOp("4 * 3", expected: 12)
        testBinaryOp("4 / 3", expected: 1)
        testBinaryOp("4 / 2", expected: 2)
        testBinaryOp("4 % 3", expected: 1)
        testBinaryOp("4 % 2", expected: 0)
        
        // logical ops: equalities and inequalities
        testBinaryOp("4 < 3", expected: false)
        testBinaryOp("3 < 4", expected: true)
        testBinaryOp("4 > 3", expected: true)
        testBinaryOp("3 > 4", expected: false)
        testBinaryOp("4 == 3", expected: false)
        testBinaryOp("4 == 4", expected: true)
        testBinaryOp("4 != 3", expected: true)
        testBinaryOp("4 != 4", expected: false)
        testBinaryOp("3 >= 4", expected: false)
        testBinaryOp("4 >= 3", expected: true)
        testBinaryOp("4 >= 4", expected: true)
        testBinaryOp("3 <= 4", expected: true)
        testBinaryOp("4 <= 3", expected: false)
        testBinaryOp("4 <= 4", expected: true)
        
        // logical ops: and, or
        testBinaryOp("true && true", expected: true)
        testBinaryOp("true && false", expected: false)
        testBinaryOp("false && true", expected: false)
        testBinaryOp("false && false", expected: false)
        testBinaryOp("true || true", expected: true)
        testBinaryOp("true || false", expected: true)
        testBinaryOp("false || true", expected: true)
        testBinaryOp("false || false", expected: false)

        // top-of-stack placeholder
        testMultiOp(expression: "7 3 % @@", expected: 3, attr: Attribution())
        testMultiOp(expression: "7 @@ % 3", expected: 1, attr: Attribution())
    }
    
    func testSelect() {
        let members = [
            (weight: 10, value: Attribution().add(for: "key", value: "a")),
            (weight: 15, value: Attribution().add(for: "key", value: 0)),
            (weight: 30, value: Attribution().add(for: "key", value: true)),
            (weight: 55, value: Attribution().add(for: "key", value: Dice(count: 2, sides: 8))),
            (weight: 75, value: Attribution().add(for: "key", value: nil)),
            (weight: 100, value: Attribution().add(for: "key", value: Attribution().add(for: "name", value: Attribute("f"))))
        ]
        let testValue = try! Distribution(members: members)
        let attr = Attribution()
        attr.add(for: "x", value: testValue)
        if let node: CallNode = testSingleExpressionParse(expression: "z = select(@x)") {
            do {
                try Calculator.TheCalculator.evaluate(nodes: [node], this: attr)
                XCTAssert(!Calculator.TheCalculator.hasValue())         // stack is empty
                if let selected = try attr.get(for: "z")?.asAttribution() {
                    var weight = 0
                    for member in members {
                        if member.value === selected {
                            weight = member.weight
                            break
                        }
                    }
                    XCTAssert(weight > 0)
                    return
                }
            }
            catch {
                print(error)
            }
            XCTFail()
        }
    }
    
    func testParens() {
        if let node: BinaryOpNode = testSingleExpressionParse(expression: "3 - 2 * 1 + 4 % 2"),
            let actual: Int = testEvaluate(node: node) {
            XCTAssertEqual(actual, 1)
        }
        if let node: BinaryOpNode = testSingleExpressionParse(expression: "3 - (2 * 1 + 4) % 2"),
            let actual: Int = testEvaluate(node: node) {
            XCTAssertEqual(actual, 3)
        }
        if let node: BinaryOpNode = testSingleExpressionParse(expression: "3 - (2 * (1 + 4 % 2))"),
            let actual: Int = testEvaluate(node: node) {
            XCTAssertEqual(actual, 1)
        }
        if let node: BinaryOpNode = testSingleExpressionParse(expression: "(3 - 2) * ((1 + 4) % 2)"),
            let actual: Int = testEvaluate(node: node) {
            XCTAssertEqual(actual, 1)
        }
    }
    
    func testIfElse() {
        let attr = Attribution()
        attr.add(for: "x", value: 4)
        
        testIfNode(expression: "@this.x == 4 if this.y = @this.x this.x = 3 endif", expected: 3, attr: attr)
        testIfNode(expression: "@this.x == 3 if this.x = 2 else this.x = 1 endif", expected: 2, attr: attr)
        testIfNode(expression: "@this.x == 3 if this.x = 2 else this.x = 1 endif", expected: 1, attr: attr)

        testIfNode(expression: "4 @this.x == 1 if this.x = @@ else drop() this.x = 1 endif", expected: 4, attr: attr)
        testIfNode(expression: "4 @this.x == 1 if this.x = @@ else drop() this.x = 1 endif", expected: 1, attr: attr)
        
        testIfNode(expression: "3 dup() == 2 if this.x = @@ * 2 else this.x = @@ endif", expected: 3, attr: attr)
        testIfNode(expression: "3 2 == dup() if this.x = @@ * 2 else this.x = @@ endif", expected: 3, attr: attr)

        XCTAssertEqual(try! attr.get(for: "y")?.asInt(), 4)
    }
    
    func testForEach() {
        let attr = Attribution()
        attr.add(for: "deck", value: Card.makeDeck())
        attr.add(for: "sum", value: 0)
        attr.add(for: "count", value: 0)

        if let nodes = testMultiExpressionParse(expression: "this.deck foreach card do this.sum += @card.rank this.count += 1 loop") {
            do {
                try Calculator.TheCalculator.evaluate(nodes: nodes, this: attr)
                XCTAssert(!Calculator.TheCalculator.hasValue())         // stack is empty
                XCTAssertEqual(try attr.get(for: "sum")?.asInt(), 364)
                XCTAssertEqual(try attr.get(for: "count")?.asInt(), 52)
                return
            } catch {
                print(error)
            }
            XCTFail()
        }
    }
    
    func testMinMax() {
        testCallNode(expression: "min(3, 6, -1, 4)", expected: -1)
        testCallNode(expression: "max(3, 6, -1, 4)", expected: 6)
    }
    
    func testExists() {
        let attr = Attribution()
        attr.add(for: "xy", value: 132)

        testCallNode(expression: "exists(this.xy)", expected: true, attr: attr)
        testCallNode(expression: "exists(this.yx)", expected: false, attr: attr)
        
        // nested attributes
        let attr2 = Attribution()
        attr2.add(for: "indirect", value: attr)
        testCallNode(expression: "exists(this.xy)", expected: false, attr: attr2)
        testCallNode(expression: "exists(this.indirect.xy)", expected: true, attr: attr2)
    }
    
    func testSigned() {
        testCallNode(expression: "signed(-1)", expected: "-1")
        testCallNode(expression: "signed(0)", expected: "+0")
        testCallNode(expression: "signed(1)", expected: "+1")
    }
    
    func testDescribe() {
        testCallNode(expression: "describe(1, \"two-handed sword\")", expected: "a two-handed sword")
        testCallNode(expression: "describe(3, \"two-handed sword\")", expected: "3 two-handed swords")
        testCallNode(expression: "describe(1, \"amber ring\")", expected: "an amber ring")
        testCallNode(expression: "describe(2, \"amber ring\")", expected: "2 amber rings")
        testCallNode(expression: "describe(1, \"potion\")", expected: "a potion")
        testCallNode(expression: "describe(4, \"potion\")", expected: "4 potions")
    }

    func testDivideByZero() {
        if let node: BinaryOpNode = testSingleExpressionParse(expression: "4 / 0") {
            XCTAssertThrowsError(try Calculator.TheCalculator.evaluate(nodes: [node], this: Attribution())) { (error) in
                do {
                    XCTAssertEqual(error.localizedDescription,
                                   CalculationError.divideByZero(error: "4").localizedDescription)
                }
            }
            XCTAssert(!Calculator.TheCalculator.hasValue())         // stack is empty
        }
    }
    
    func testMultiOp<T: Equatable>(expression: String, expected: T, attr: Attribution) {
        if let nodes = testMultiExpressionParse(expression: expression) {
            do {
                try Calculator.TheCalculator.evaluate(nodes: nodes, this: attr)
                XCTAssert(Calculator.TheCalculator.hasValue())         // stack is not empty
                if let actual = try Calculator.TheCalculator.value()?.asType(T.self) {
                    XCTAssertEqual(expected, actual)
                }
                return
            }
            catch {
                print(error)
            }
            XCTFail()
        }
    }

    private func testIfNode<T: Equatable>(expression: String, expected: T, attr: Attribution) {
        if let nodes = testMultiExpressionParse(expression: expression) {
            do {
                try Calculator.TheCalculator.evaluate(nodes: nodes, this: attr)
                XCTAssert(!Calculator.TheCalculator.hasValue())         // stack is empty
                XCTAssertEqual(try attr.get(for: "x")?.asType(T.self), expected)
                return
            } catch {
                print(error)
            }
        }
        XCTFail()
    }
    
    private func testCallNode<T: Equatable>(expression: String, expected: T) {
        testCallNode(expression: expression, expected: expected, attr: Attribution())
    }

    private func testCallNode<T: Equatable>(expression: String, expected: T, attr: Attribution) {
        if let node: CallNode = testSingleExpressionParse(expression: expression),
            let actual: T = testEvaluate(node: node, args: attr) {
            XCTAssertEqual(expected, actual)
        }
        else {
            XCTFail()
        }
        XCTAssert(!Calculator.TheCalculator.hasValue())         // stack is empty
    }
    
    private func attrTypeError(expression: String, message: String) {
        let attr = Attribution()
        attr.add(for: "x", value: "xyzzy")
        attr.add(for: "y", value: -1)
        
        if let node: UnaryOpNode = testSingleExpressionParse(expression: expression) {
            do {
                XCTAssertThrowsError(try Calculator.TheCalculator.evaluate(nodes: [node], this: attr)) { (error) in
                    do {
                        XCTAssertEqual(error.localizedDescription, message)
                    }
                }
                XCTAssert(!Calculator.TheCalculator.hasValue())         // stack is empty
            }
        }
    }

    private func attrMissingError(expression: String, message: String) {
        let attr = Attribution()
        attr.add(for: "y", value: 3)
        
        if let node: UnaryOpNode = testSingleExpressionParse(expression: expression) {
            do {
                XCTAssertThrowsError(try Calculator.TheCalculator.evaluate(nodes: [node], this: attr)) { (error) in
                    do {
                        XCTAssertEqual(error.localizedDescription,
                                       AttributionError.missingAttribute(for: message).localizedDescription)
                    }
                }
                XCTAssert(!Calculator.TheCalculator.hasValue())         // stack is empty
            }
        }
    }

    private func assignmentTest(expression: String, attr: Attribution, actual: Int) {
        if let node: BinaryOpNode = testSingleExpressionParse(expression: expression) {
            do {
                try Calculator.TheCalculator.evaluate(nodes: [node], this: attr)
                XCTAssert(!Calculator.TheCalculator.hasValue())          // stack is not empty
                XCTAssert(try attr.get(for: "x")?.asInt() == actual)
                return
            }
            catch {
                print(error)
            }
        }
        XCTFail()
    }

    private func testIncrDecr(expression: String, attr: Attribution, actual: Int) {
        if let node: UnaryOpNode = testSingleExpressionParse(expression: expression) {
            do {
                try Calculator.TheCalculator.evaluate(nodes: [node], this: attr)
                XCTAssertEqual(try attr.get(for: "x")?.asInt(), actual)
                return
            }
            catch {
                print(error)
            }
        }
        XCTFail()
    }

    private func testUnaryOp<T : Equatable>(_ expression: String, expected: T) {
        if let node: UnaryOpNode = testSingleExpressionParse(expression: expression),
            let actual : T = testEvaluate(node: node) {
            XCTAssert(expected == actual)
            return
        }
        XCTFail()
    }

    private func testBinaryOp<T : Equatable>(_ expression: String, expected: T) {
        if let node: BinaryOpNode = testSingleExpressionParse(expression: expression),
            let actual : T = testEvaluate(node: node) {
            XCTAssert(expected == actual)
            return
        }
        XCTFail()
    }
    
    private func testEvaluate<T>(node: ExprNode) -> T? {
        return testEvaluate(node: node, args: Attribution())
    }
    
    private func testEvaluate<T>(node: ExprNode, args: Attribution) -> T? {
        do {
            try Calculator.TheCalculator.evaluate(nodes: [node], this: args)
            XCTAssert(Calculator.TheCalculator.hasValue())          // stack is not empty
            let actual = try Calculator.TheCalculator.value()!.asType(T.self)
            
            XCTAssert(!Calculator.TheCalculator.hasValue())         // stack is empty
            return actual
        } catch {
            print(error)
        }
        XCTFail(node.description)
        
        return nil;     // not reached
    }

    private func testSingleExpressionParse<T : ExprNode>(expression: String) -> T? {
        if let nodes = Calculator.TheCalculator.parse(expression) {
            XCTAssert(nodes.count == 1, expression)
            let node = nodes.last
            return node as? T;
        }
        XCTFail(expression)
        
        return nil;      // not reached
    }

    private func testMultiExpressionParse(expression: String) -> [ExprNode]? {
        if let nodes = Calculator.TheCalculator.parse(expression) {
            XCTAssert(nodes.count > 1, expression)
            return nodes
        }
        XCTFail(expression)
        
        return nil;      // not reached
    }
}
