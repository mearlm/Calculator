//
//  Attribution.swift
//  Calculator
//
//  Created by Michael McGhan on 3/10/19.
//  Copyright © 2019 MSQR Laboratories. All rights reserved.
//

import Foundation

// dictionaries of variously typed attribute values, accessable by address
open class Attribution : Subject, Equatable {
    private var attributes = [String : Attributable]()

    override
    public init() {
        super.init()
    }
    
    convenience public init(parent: Attribution) {
        self.init()
        self._parent = parent                           // original parent is nil
    }
    
    // i.e. clone, but with unique id
    public convenience init(from original: Attribution) {
        self.init()
        self.reparent(parent: original._parent)         // NB: optional parent
        self.attributes = original.attributes           // copy on write?
    }

    override
    public func findChildKey(for childId: Int) -> String? {
        let children = self.attributes.filter( {
            if let child = $0.value.rawValue() as? Addressable {
                return childId == child.getUniqueId()
            }
            return false
        } )
        return (!children.isEmpty) ? children.first!.key : nil      // should only ever be one item matching a given ID
    }
    
    private func fullPath(key: String) -> Address {
        var parts: [String] = []
        if let address = self.getAddress() {
            parts = Address.splitKey(address: address.asString())
        }
        return Address(Address.composeKey(path: parts, key: key))!
    }
    
    @discardableResult
    public func add(for key: String, value: Attributable?) -> Attribution {
        guard let value = value else {
            return self.remove(for: key)
        }
        
        let previous = self.attributes[key]
        self.attributes[key] = value
        if var child = value.rawValue() as? Addressable {
            child.reparent(parent: self)
        }
        
        notify(at: fullPath(key: key), was: previous)
        return self         // allows chaining adds
    }
    
    @discardableResult
    public func add<T>(for key: String, value: T?) -> Attribution {
        if (nil == value) {
            return self.remove(for: key)
        }
        return self.add(for: key, value: Attribute(value!))
    }
    
    @discardableResult
    public func remove(for key: String) -> Attribution {
        if let previous = self.attributes[key] {
            self.attributes.removeValue(forKey: key)
            notify(at: fullPath(key: key), was: previous)
        }
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
