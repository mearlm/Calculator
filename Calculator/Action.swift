//
//  Action.swift
//  Calculator
//
//  Created by Michael McGhan on 6/17/18.
//  Copyright © 2018 MSQR Laboratories. All rights reserved.
//

import Foundation

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

//    // if
//    private static func ifThen() throws {
//        guard let cond = try pop()?.asBool(),
//            let action = try pop()?.asAction(),
//            let other = try pop()?.asAction(),
//            let args = try pop()?.asAttribution() else {
//            throw CalculationError.emptyStackError
//        }
//        _ = Action.run(first: (cond) ? action : other, args: args)
//    }

//    // else
//    private static func ifElse() throws {
//        guard let args = try pop()?.asAttribution() else {
//            throw CalculationError.emptyStackError
//        }
//        push(nil)
//        push(args)
//        try ifThenElse()
//    }
//
//    // for-each
//    private static func doForEach() throws {
//        guard let objects = try pop()?.asAttribution(),
//            let action = try pop()?.asAction() else {
//            throw CalculationError.emptyStackError
//        }
//        for key in objects.keys() {
//             let object = try objects.get(for: key)!.asAttribution()
//            _ = ActionImpl.run(first: action, args: object)
//        }
//    }
//
//    // for
//    private static func doFor() throws {
//        guard let limit = try pop()?.asInt(),
//            let args = try pop()?.asAttribution(),
//            let action = try pop()?.asAction() else {
//            throw CalculationError.emptyStackError
//        }
//        for ix in 1..<limit {
//            args.put("index", new Attribute(ix))
//            _ = ActionImpl.run(first: action, args: args)
//        }
//    }

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
