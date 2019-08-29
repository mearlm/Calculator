//
//  Attribute.swift
//  iRogue
//
//  Created by Michael McGhan on 6/9/18.
//  Copyright © 2018 MSQR Laboratories. All rights reserved.
//

import Foundation

public enum AttributionError : LocalizedError {
    case missingAttribute(for: String)                      // no such attribute in Attribution
    case invalidDereference(error: String)                  // attribute dereference returned wrong type
    case invalidDistribution(error: String)                 // distribution failed to select
    case invalidFetch(expected: String, received: String)   // address returned unexpected type
    case containerFull(max: Int)                            // attempting an add when container is full
    case runtimeError(error: String)                        // generic error
    
    public var errorDescription: String? {
        switch self {
        case let .missingAttribute(name):
            return "missing attribute: \(name)"
        case let .invalidFetch(expected, received):
            return "expected: \(expected) received: \(received)"
        case let .invalidDereference(error),
             let .invalidDistribution(error),
             let .runtimeError(error):
            return "invalid: \(error)"
        case let .containerFull(count):
            return "container full (max=\(count))"
        }
    }
    
// alternate style with parameters
//    var errorDescription: String {
//        switch self {
//        case .responseStatusError(status: let status, message: let message):
//            return "Error with status \(status) and message \(message) was thrown"
//        }
//    }
}

// attribute collections:
// Game -> attributes
// Hero -> game.hero.attributes (see Address)
// CurrentLevel -> game.level[game.currentLevel].attributes
// Options -> game.options
// Stats -> game.stats (?)
// Pack -> hero/creature.pack.attributes (??)
// Thing: Creature, ValuableThing ->
//    attributes + Prototype, derivedFrom -> attributes/invarients
// Event -> attributes

public protocol Attributable {
    func rawValue() -> Any
    func asInt() throws -> Int
    func asString() throws -> String
    func asBool() throws -> Bool
    func asDice() throws -> Dice
    func asAddress() throws -> Address
    func asAttribution() throws -> Attribution
    func asDistribution<E: Equatable>(of: E.Type) throws -> Distribution<E>
    func asContainer<E: Equatable>(of ctype: E.Type) throws -> Container<E>
    func asCollection() throws -> AnyCollection<Attributed>?
    func asType<E>(_ type: E.Type) throws -> E
    func isEqual(other: Attributable) -> Bool
    
    func describe(resolve: Bool, within: Attribution?) throws -> String
}

public struct Attribute<T> : Attributable {
    let value: T
    
    public init(_ value: T) {
        self.value = value
    }
    
    private func tryCast<R>(as rtype: R.Type) throws -> R {
        if let result = value as? R {
            return result
        }
        throw AttributionError.invalidDereference(error: "For \(type(of: value as Any)), requested: \(type(of: rtype as Any))")
    }
    
    public func rawValue() -> Any {
        return value
    }
    
    // for attribute types not specified explicitly:
    public func asType<E>(_ type: E.Type) throws -> E {
        return try tryCast(as: E.self)
    }
    
    public func asInt() throws -> Int {
        return try tryCast(as: Int.self)
    }
    
    public func asString() throws -> String {
        return try tryCast(as: String.self)
    }
    
    public func asBool() throws -> Bool {
        return try tryCast(as: Bool.self)
    }
    
    public func asDice() throws -> Dice {
        return try tryCast(as: Dice.self)
    }
    
    public func asAddress() throws -> Address {
        return try tryCast(as: Address.self)
    }

    public func asAttribution() throws -> Attribution {
        return try tryCast(as: Attribution.self)
    }

    public func asDistribution<E: Equatable>(of: E.Type) throws -> Distribution<E> {
        return try tryCast(as: Distribution<E>.self)
    }

    public func asContainer<E: Equatable>(of ctype: E.Type) throws -> Container<E> {
        return try tryCast(as: Container<E>.self)
    }
    
    public func asCollection() -> AnyCollection<Attributed>? {
        if let result = value as? AnyCollection<Attributed> {
            return result
        }
        return nil
    }

//    public func asAction() throws -> Action {
//        return try tryCast(as: Action.self)
//    }
    
    public func describe() throws -> String {
        return try describe(resolve: false, within: nil)
    }

    public func describe(resolve: Bool, within args: Attribution?) throws -> String {
        let valueType = type(of: value as Any)
        if valueType == Address.self {
            if resolve, let args = args {
                guard let result = try self.asAddress().fetch(args: args) else {
                    return ""       // no such attribute in args
                }
                return try result.describe(resolve: resolve, within: args)
            }
            else {
                let result = try self.asAddress()
                return result.asString()
            }
        }
        if (valueType == Dice.self) {
            return try! self.asDice().asString()
        }
        return String(describing: value)
    }
    
    private static func equalAny<BaseType: Equatable>(lhv: Any, rhv: Any, baseType: BaseType.Type) -> Bool {
        guard let lhsEquatable = lhv as? BaseType,
            let rhsEquatable = rhv as? BaseType else {
            return false
        }
        return lhsEquatable == rhsEquatable
    }
    
    public func isEqual(other: Attributable) -> Bool {
        let baseType = type(of: value as Any)           // actual type of (generic object) value
        let otherValue = other.rawValue()

        guard baseType == type(of: otherValue as Any) else {
            return false
        }

        if (baseType == Int.self) {
            return Attribute.equalAny(lhv: self.value, rhv: otherValue, baseType: Int.self)
        }
        else if (baseType == String.self) {
            return Attribute.equalAny(lhv: self.value, rhv: otherValue, baseType: String.self)
        }
        else if (baseType == Bool.self) {
            return Attribute.equalAny(lhv: self.value, rhv: otherValue, baseType: Bool.self)
        }
        else if (baseType == Dice.self) {
            return Attribute.equalAny(lhv: self.value, rhv: otherValue, baseType: Dice.self)
        }
        else if (baseType == Address.self) {
            return Attribute.equalAny(lhv: self.value, rhv: otherValue, baseType: Address.self)
        }
        else if (baseType == Attribution.self) {
            return Attribute.equalAny(lhv: self.value, rhv: otherValue, baseType: Attribution.self)
        }
        else {      // NB: can't compare generic Distribution-type attributes
//            return Attribute.equalAny(lhv: self.value, rhv: other.value, baseType: Distribution<T>.self)
        }
        return false
    }
}
extension Attribute: Equatable where T: Equatable {
    public static func == (lhs: Attribute<T>, rhs: Attribute<T>) -> Bool {
        return lhs.value == rhs.value
    }
}

public struct Dice : Equatable {
    public let count: Int
    public let sides: Int

    public func asString() -> String {
        return String(count) + "d" + String(sides)
    }
}
