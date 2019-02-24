//
//  Attribute.swift
//  iRogue
//
//  Created by Michael McGhan on 6/9/18.
//  Copyright © 2018 MSQR Laboratories. All rights reserved.
//

import Foundation

public enum AttributionError : Error {
    case missingAttribute(for: String)                      // no such attribute in Attribution
    case invalidDereference(error: String)                  // attribute dereference returned wrong type
    case invalidDistribution(error: String)                 // distribution failed to select
    case invalidFetch(expected: String, received: String)   // address returned unexpected type
}

// attribute collections:
// Game -> attributes
// Hero -> game.hero.attributes
// CurrentLevel -> game.level[game.currentLevel].attributes
// Options -> game.options
// Stats -> game.stats (?)
// Pack -> hero/creature.pack.attributes (??)
// Thing: Creature, ValuableThing ->
//    attributes + Prototype, derivedFrom -> attributes/invarients
// Event -> attributes

//typealias Dice = (count: Int, sides: Int)

public protocol Attributable {
    func rawValue() -> Any
    func asInt() throws -> Int
    func asString() throws -> String
    func asBool() throws -> Bool
    func asDice() throws -> Dice
    func asAddress() throws -> Address
    func asAttribution() throws -> Attribution
    func asDistribution<E: Equatable>(of: E.Type) throws -> Distribution<E>
    func asType<E>(_ type: E.Type) throws -> E
    func isEqual(other: Attributable) -> Bool
    
    func describe(resolve: Bool, within: Attribution) throws -> String
}

public struct Attribute<T> : Attributable {
    let valueType: Any.Type
    let value: T
    
    public init(_ value: T) {
        self.value = value
        self.valueType = type(of: value as Any)
    }

    private func validate(requested: Any.Type) -> Error? {
        return (self.valueType == requested)
            ? nil
            : AttributionError.invalidDereference(error: "For \(self.valueType), requested: \(requested).")
    }
    
    public func rawValue() -> Any {
        return value
    }
    
    public func asType<E>(_ type: E.Type) throws -> E {
        if let error = validate(requested: type) {
            throw error
        }
        return (value as! E)
    }
    
    public func asInt() throws -> Int {
        if let error = validate(requested: Int.self) {
            throw error
        }
        return (value as! Int)
    }
    
    public func asString() throws -> String {
        if let error = validate(requested: String.self) {
            throw error
        }
        return (value as! String)
    }
    
    public func asBool() throws -> Bool {
        if let error = validate(requested: Bool.self) {
            throw error
        }
        return (value as! Bool)
    }
    
    public func asDice() throws -> Dice {
        if let error = validate(requested: Dice.self) {
            throw error
        }
        return (value as! Dice)
    }
    
    public func asAddress() throws -> Address {
        if let error = validate(requested: Address.self) {
            throw error
        }
        return (value as! Address)
    }

    public func asAttribution() throws -> Attribution {
        if let error = validate(requested: Attribution.self) {
            throw error
        }
        return (value as! Attribution)
    }
    
    public func asDistribution<E: Equatable>(of: E.Type) throws -> Distribution<E> {
        if let error = validate(requested: Distribution<E>.self) {
            throw error
        }
        return (value as! Distribution<E>)
    }
    
    public func describe(resolve: Bool, within args: Attribution) throws -> String {
        if (resolve && valueType == Address.self) {
            guard let result = try self.asAddress().fetch(args: args) else {
                return ""       // no such attribute in args
            }
            return try result.describe(resolve: resolve, within: args)
        }
        if (valueType == Dice.self) {
            return try! self.asDice().asString()
        }
        return String(describing: value)
    }
    
//    public func asAction() throws -> Action {
//        if let error = validate(requested: Action.self) {
//            throw error
//        }
//        return (value as! Action)
//    }
    
    private static func equalAny<BaseType: Equatable>(lhv: Any, rhv: Any, baseType: BaseType.Type) -> Bool {
        guard let lhsEquatable = lhv as? BaseType,
            let rhsEquatable = rhv as? BaseType else {
            return false
        }
        return lhsEquatable == rhsEquatable
    }
    
    public func isEqual(other: Attributable) -> Bool {
        let otherValue = other.rawValue()
        
        guard valueType == type(of: otherValue as Any) else {
            return false
        }
        
        if (self.valueType == Int.self) {
            return Attribute.equalAny(lhv: self.value, rhv: otherValue, baseType: Int.self)
        }
        else if (self.valueType == String.self) {
            return Attribute.equalAny(lhv: self.value, rhv: otherValue, baseType: String.self)
        }
        else if (self.valueType == Bool.self) {
            return Attribute.equalAny(lhv: self.value, rhv: otherValue, baseType: Bool.self)
        }
        else if (self.valueType == Dice.self) {
            return Attribute.equalAny(lhv: self.value, rhv: otherValue, baseType: Dice.self)
        }
        else if (self.valueType == Address.self) {
            return Attribute.equalAny(lhv: self.value, rhv: otherValue, baseType: Address.self)
        }
        else if (self.valueType == Attribution.self) {
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

// dictionaries of typed property values
public class Attribution : Equatable {
    private static var nextId = 1
    private static func getNextId() -> Int {
        let result = nextId
        nextId += 1
        
        return result
    }
    
    private var attributes = [String : Attributable]()

    public init() {
        self.add(for: "id", value: Attribute(Attribution.getNextId()))
    }

    public init(from original: Attribution) {
        self.attributes = original.attributes     // copy on write?
        self.attributes["id"] = Attribute(Attribution.getNextId())
    }

    @discardableResult
    public func add(for key: String, value: Attributable?) -> Attribution {
        if (nil == value) {
            _ = self.remove(for: key)
        }
        else {
            self.attributes[key] = value!
        }
        return self         // allows chaining adds
    }

    @discardableResult
    public func remove(for key: String) -> Attribution {
        self.attributes.removeValue(forKey: key)
        return self         // allows chaining removes
    }

    public func get(for key: String) -> Attributable? {
        return attributes[key]
    }
    
    public func containsKey(for key: String) -> Bool {
        return self.attributes.keys.contains(key)
    }
    
    public func keys() -> [String] {
        return Array(self.attributes.keys)
    }
    
    public func count() -> Int {
        return attributes.count
    }

    public static func ==(lhs: Attribution, rhs: Attribution) -> Bool {
        if lhs === rhs {
            return true         // identical object instances
        }
        guard lhs.count() == rhs.count() else {
            return false
        }

        for (key, value) in lhs.attributes {
            guard !rhs.containsKey(for: key) else {
                return false
            }
            let rhval = rhs.get(for: key)!
            
            guard (value.isEqual(other: rhval)) else {
                return false
            }
        }
        return true
    }
}

public protocol Attributed {
    var attributes: Attribution { get }
}

