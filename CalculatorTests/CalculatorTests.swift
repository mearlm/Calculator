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
    
}
