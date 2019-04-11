//
//  Notifiable.swift
//  Calculator
//
//  Created by Michael McGhan on 3/16/19.
//  Copyright © 2019 MSQR Laboratories. All rights reserved.
//

import Foundation

// some concepts taken from:
// https://medium.com/@samstone/design-patterns-in-swift-observer-pattern-51274d34f9e3

public protocol Observer {
    var id : Int { get }        // unique
    func update(at: Address, was: Attributable?)
}

public protocol Notifiable {
    func subscribe(observer: Observer)
    func unsubscribe(observer: Observer)
}

// base class for Notifiable subjects
// i.e. mutable container objects: Container, Attribution, but not immutable Distribution
open class Subject : Notifiable, Addressable {
    private static var nextId = 1
    internal static func getNextId() -> Int {
        let result = nextId
        nextId += 1
        
        return result
    }
    
    // Notifiable
    private var observers = [Observer]()
    
    // Addressable
    public var _parent: Addressable? = nil
    public var _id: Int

    public init() {
        _id = Subject.getNextId()
    }

    public func findChildKey(for childId: Int) -> String? {
        fatalError(#function + " must be overridden!")
    }
    
    @discardableResult
    public func reparent(parent: Addressable?) -> Addressable? {
        let result = self._parent
        self._parent = parent
        
        return result
    }

    // Notifiable
    public func subscribe(observer : Observer) {
        observers.append(observer)
    }
    
    public func unsubscribe(observer: Observer) {
        observers = observers.filter({ $0.id != observer.id })
    }
    
    func notify(at: Address, was: Attributable?) {
        for observer in observers {
            observer.update(at: at, was: was)
        }
    }
}
