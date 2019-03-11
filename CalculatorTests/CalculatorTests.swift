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
    
}
