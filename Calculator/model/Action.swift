//
//  Action.swift
//  Calculator
//
//  Created by Michael McGhan on 6/17/18.
//  Copyright © 2018 MSQR Laboratories. All rights reserved.
//

import Foundation

// an action contains pre-compiled (i.e. parsed) code, ready to act on an item (Attribution)
public class Action {
    private let nodes: [ExprNode]
    
    public init?(expression: String) {
        guard let nodes = Calculator.TheCalculator.parse(expression) else {
            return nil
        }
        self.nodes = nodes
    }
    
    public func act(on item: Attribution) -> Bool {
        var result = false
        do {
            try Calculator.TheCalculator.evaluate(nodes: nodes, this: item)
            result = true
        }
        catch {
            print(error)        // ToDo: log error
        }
        return result
    }
}

//public protocol Action {
//    func act(_ args: Attribution) -> Bool
//    func next() -> Action?
//}
//extension Action {
//    // run a sequence of actions
//    public static func run(first: Action, args: Attribution) -> Bool {
//        var result = false
//        var action : Action? = first
//
//        repeat {
//            result = action!.act(args)
//            action = action!.next()
//        } while (result && action != nil)
//
//        return result
//    }
//}

// special actions:

//    // filter(predicate)
//    private static func filter() throws {
//        guard let objects = try pop()?.asAttribution(),
//            let predicate = try pop()?.asAction() else {    // needs to be a parsed (boolean) expression
//            throw CalculationError.emptyStackError
//        }
//        var result: Attribution
//
//        for key in objects.keys() {
//            let object = try objects.get(for: key)!.asAttribution()
//            if ActionImpl.run(first: predicate, args: object) {
//                result.put(key, object)
//            }
//        }
//        push(result)
//    }
//
//  notifyUIAction...
