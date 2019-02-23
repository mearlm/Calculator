//
//  Container.swift
//  iRogue
//
//  Created by Michael McGhan on 6/10/18.
//  Copyright © 2018 MSQR Laboratories. All rights reserved.
//

import Foundation

public protocol Container: Sequence {
    associatedtype T : Attributed
    
    var things: [T] { get }
    var capacity: Int { get }

    func add(thing: T) -> Bool
    func remove(thing: T) -> Bool
    
    //func makeIterator() -> Array<Attributed>.Iterator
}
extension Container {
    public static var UNLIMITED : Int {
        get {
            return -1
        }
    }
    
    public func makeIterator() -> IndexingIterator<[Self.T]> {
        return things.makeIterator()
    }
}
