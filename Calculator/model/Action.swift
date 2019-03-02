//
//  Action.swift
//  Calculator
//
//  Created by Michael McGhan on 6/17/18.
//  Copyright © 2018 MSQR Laboratories. All rights reserved.
//

import Foundation

public protocol Action {
    func act(_ args: Attribution) -> Bool
    func next() -> Action?
}
extension Action {
    // run a sequence of actions
    public static func run(first: Action, args: Attribution) -> Bool {
        var result = false
        var action : Action? = first
        
        repeat {
            result = action!.act(args)
            action = action!.next()
        } while (result && action != nil)
        
        return result
    }
}

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
