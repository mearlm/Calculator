//
//  Attribution.swift
//  Calculator
//
//  Created by Michael McGhan on 3/10/19.
//  Copyright © 2019 MSQR Laboratories. All rights reserved.
//

import Foundation

// dictionaries of typed property values
open class Attribution : Equatable, Addressable {
    private static var nextId = 1
    internal static func getNextId() -> Int {
        let result = nextId
        nextId += 1
        
        return result
    }
    
    private var attributes = [String : Attributable]()
    public var _parent: Addressable? = nil
    public let _id: Int                                 // immutable, unique

    public init() {
        _id = Attribution.getNextId()
    }
    
    convenience public init(parent: Attribution) {
        self.init()
        self._parent = parent
    }
    
    public convenience init(from original: Attribution) {
        self.init()
        self._parent = original._parent                 // NB: optional parent
        self.attributes = original.attributes           // copy on write?
    }
    
    // allow for changing the parent of an Attribution or Container
    // (this is not supported for Distributions)
    public func reparent(parent: Addressable) -> Addressable? {
        let result = self._parent
        self._parent = parent
        
        return result
    }

    public func findChildKey(for childId: Int) -> String? {
        let children = self.attributes.filter( {
            if let child = $0.value as? Addressable {
                return childId == child.getUniqueId()
            }
            return false
        } )
        return (!children.isEmpty) ? children.first!.key : nil      // should only ever be one item matching a given ID
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
    public func add<T>(for key: String, value: T?) -> Attribution {
        if (nil == value) {
            _ = self.remove(for: key)
        }
        else {
            self.add(for: key, value: Attribute(value!))
        }
        return self
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
    
    internal func isEqual(other: Attribution) -> Bool {
        guard self.count() == other.count() else {
            return false
        }
        
        for (key, value) in self.attributes {
            guard other.containsKey(for: key) else {
                return false
            }
            let rhval = other.get(for: key)!
            
            guard (value.isEqual(other: rhval)) else {
                return false
            }
        }
        return true
    }
    
    public static func ==(lhs: Attribution, rhs: Attribution) -> Bool {
        if lhs === rhs {
            return true         // identical object instances
        }
        return lhs.isEqual(other: rhs)
    }
}

public protocol Attributed {
    var attributes: Attribution { get }
}
