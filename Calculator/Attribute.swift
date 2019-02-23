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

public struct Attribute<T> {
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
    
    func rawValue() -> T {
        return value
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
    
    func asDice() throws -> Dice {
        if let error = validate(requested: Dice.self) {
            throw error
        }
        return (value as! Dice)
    }
    
    func asAddress() throws -> Address {
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
    
    public func isEqual(other: Attribute) -> Bool {
        guard valueType == other.valueType else {
            return false
        }
        
        if (self.valueType == Int.self) {
            return Attribute.equalAny(lhv: self.value, rhv: other.value, baseType: Int.self)
        }
        else if (self.valueType == String.self) {
            return Attribute.equalAny(lhv: self.value, rhv: other.value, baseType: String.self)
        }
        else if (self.valueType == Bool.self) {
            return Attribute.equalAny(lhv: self.value, rhv: other.value, baseType: Bool.self)
        }
        else if (self.valueType == Dice.self) {
            return Attribute.equalAny(lhv: self.value, rhv: other.value, baseType: Dice.self)
        }
        else if (self.valueType == Address.self) {
            return Attribute.equalAny(lhv: self.value, rhv: other.value, baseType: Address.self)
        }
        else if (self.valueType == Attribution.self) {
            return Attribute.equalAny(lhv: self.value, rhv: other.value, baseType: Attribution.self)
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
}

// NB: in a given distribution, all values are the same type (T), e.g. String
public typealias Membership<T> = [(weight: Int, value: T)]

// weights: an ascending sequence of Ints greater than (or equal to) 1, and ending at 100
// describing the probability of selecting the associated value
public struct Distribution<T: Equatable>: Equatable {
    private var members = Membership<T>()
    private var last: (weight: Int, value: T) {
        get { return members.last! }
    }
    
    public init?(members: Membership<T>) {
        guard validate(members) else {
            return nil
        }
        self.members = members
    }

    private func logError(error: String) {
        // ToDo: add a proper error logging service
        print(error)
    }

    private func validate(_ members: Membership<T>) -> Bool {
        var weight = 0
        for member in members {
            if member.weight <= weight {
                logError(error: "Distribution not ascending after \(weight).")
                return false
            }
            weight = member.weight
        }
        if (100 != weight) {
            logError(error: "Distribution unterminated at \(weight).")
            return false
        }
        return true
    }
    
    public func select() -> T {
        let selector = Calculator<T>.rand(self.last.weight)     // e.g. 0 - 99
        for member in self.members {
            if (member.weight >= selector) {
                return member.value
            }
        }
        return self.last.value                                  // should never happen
    }
    
    public static func ==(lhs: Distribution, rhs: Distribution) -> Bool {
        guard lhs.members.count == rhs.members.count else {
            return false
        }
        
        for ix in lhs.members.indices {
            if lhs.members[ix] != rhs.members[ix] {
                return false
            }
        }
        return true
    }
}

class Address : Equatable {
    private let key: String
    private let path: [String]
    
    init(_ address: String) {
        var parts = address.split(separator: ".")
        self.key = String(parts.removeLast())
        self.path = parts.map{String($0)}
    }
    
    private func resolvePath(args: Attribution) throws -> Attribution {
        var attribution = args
        
        for part in self.path {
            guard let next = attribution.get(for: part) else {
                let message = "Attribution \(self.path.joined()) at \(part)"
                throw AttributionError.missingAttribute(for: message)
            }
            attribution = try next.asAttribution()
        }
        return attribution
    }
    
    func exists(args: Attribution) throws -> Bool {
        let attribution = try resolvePath(args: args)
        return attribution.containsKey(for: self.key)
    }
    
    func fetch(args: Attribution) throws -> Any {
        let attribution = try resolvePath(args: args)
        guard let result = attribution.get(for: self.key) else {
            let message = "Attribute \(self.path.joined()).\(self.key)"
            throw AttributionError.missingAttribute(for: message)
        }
        
        return result.rawValue()
    }
    
    func fetch<T>(args: Attribution) throws -> T {
        let value = try self.fetch(args: args)
        if let result = value as? T {
            return result
        }
        throw AttributionError.invalidFetch(expected: String(describing: T.self), received: String(describing: type(of: value)))
    }
    
    // NB: store a nil value => delete key from Attribution
    func store<T: Equatable>(value: T?, args: Attribution) throws {
        let attribution = try resolvePath(args: args)
        attribution.add(for: key, value: value)
    }
    
    static func ==(lhs: Address, rhs: Address) -> Bool {
        return lhs.key == rhs.key && lhs.path == rhs.path
    }
}

// dictionaries of typed property values
public class Attribution : Equatable {
    private var attributes = [String : Attribute<Any>]()

    public init() {
    }

    public init(from collection: Attribution) {
        self.attributes = collection.attributes     // copy on write
    }

    @discardableResult
    public func add(for key: String, value: Any?) -> Attribution {
        if (nil == value) {
            _ = self.remove(for: key)
        }
        else {
            let attribute = Attribute(value!)
            self.attributes[key] = attribute
        }
        return self         // allows chaining adds
    }

    @discardableResult
    public func remove(for key: String) -> Attribution {
        self.attributes.removeValue(forKey: key)
        return self         // allows chaining removes
    }

    public func get(for key: String) -> Attribute<Any>? {
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

