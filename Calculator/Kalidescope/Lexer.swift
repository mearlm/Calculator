//
//  Lexer.swift
//  Kaleidoscope
//
//  Created by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//

import Foundation

public enum Token {
//    case Define
    case Identifier(String)
    case Number(Int)
    case ParensOpen
    case ParensClose
    case Comma
    case NoOp
    case Other(String)
    case UnaryOp(String)
    case BinaryOp(String)
    case Dice(count: Int, sides: Int)
    case Boolean(String)
    case StringLiteral(String)
    case IfElse(String)
    case ForEach(String)
    case SubNode(String)
}
extension Token: Equatable {
}
public func ==(lhs: Token, rhs: Token) -> Bool {
    // print("lhs: \(lhs), rhs: \(rhs)")
    switch (lhs, rhs) {
    case (let .Identifier(code1), let .Identifier(code2)),
         (let .Other(code1), let .Other(code2)),
         (let .Boolean(code1), let .Boolean(code2)),
         (let .UnaryOp(code1), let .UnaryOp(code2)),
         (let .BinaryOp(code1), let .BinaryOp(code2)):
        return code1 == code2
        
    case (let .Number(val1), let .Number(val2)):
        return val1 == val2
        
    case (let .Dice(val1), let .Dice(val2)):
        return val1.count == val2.count && val1.sides == val2.sides
        
//    case (.Define, .Define):
//         fallthrough
    case (.ParensOpen, .ParensOpen),
         (.ParensClose, .ParensClose),
         (.Comma, .Comma),
         (.NoOp, .NoOp),
         (.IfElse, .IfElse),
         (.ForEach, .ForEach),
         (.SubNode, .SubNode):
        return true
        
    default:
        return false
    }
}

// UnaryOp: +n, -n, !f, @a, ++m, --z
// Boolean: true TRUE True TrUe ... false ...
// Dice: 1d1 through 99d99, e.g. 4d6, 3d10
// Whitespace (ignored) " " (space), \t (tab), \n (new-line), \r (carriage-return), \f (form-feed)
// StringLiteral: double-quoted string, optionally containing escaped (doubled) quotes, e.g. "xy""zz""y"
// Identifier: leading letter/underscore + letters, underscores, or digits, e.g. _An_Identifier, but not 0xyzzy0
// Number (integer):
// IfElse: x == 3 if x = 2 else x = 1 endif

typealias TokenGenerator = ([String]) -> Token?
let tokenList: [(String, TokenGenerator)] = [
    ("\\s", { _ in nil }),
    ("\\(", { _ in .ParensOpen }),
    ("\\)", { _ in .ParensClose }),
    (",", { _ in .Comma }),
    ("@@(?=\\s|\\z)", {_ in .NoOp }),
    ("(?i:true|false)\\b", { .Boolean($0[0]) }),
    ("([1-9]\\d?)d([1-9]\\d?)\\b", { .Dice(count: ($0[1] as NSString).integerValue, sides: ($0[2] as NSString).integerValue) }),
    ("\"(([^\"]|\"\")*)\"", { .StringLiteral($0[1]) }),
    ("(?i)if\\b", { .IfElse($0[0]) }),
    ("(?i)foreach\\b", { .ForEach($0[0]) }),
    ("(?i:else|endif|do|loop)\\b", { .SubNode($0[0]) }),
    ("[a-zA-Z_][\\w\\.]*\\b", { .Identifier($0[0]) }),
    // ("[a-zA-Z_][\\w\\.]*\\b", { $0[0] == "def" ? .Define : .Identifier($0[0]) }),
    ("[0-9]+\\b", { .Number(($0[0] as NSString).integerValue) }),
    ("([+-](?=[0-9@])|!(?=[a-zA-Z_@\\(])|@(?=[a-zA-Z_])|\\+\\+(?=[a-zA-Z_])|\\-\\-(?=[a-zA-Z_]))", { .UnaryOp($0[1]) }),
    ("([+\\-*/]=|[=+\\-*/%<>]|&&|\\|\\||<=|==|>=|!=)(?=\\s|\\w|\\()", { .BinaryOp($0[1]) }),
]

public class Lexer {
    let input: String
    
    init(input: String) {
        self.input = input
    }
    
    public func tokenize() -> [Token] {
        var tokens = [Token]()
        var content = input
        
        while (content.count > 0) {
            var matched = false
            
            for (pattern, generator) in tokenList {
                if let m = content.match(regex: pattern) {
                    if let t = generator(m) {
                        tokens.append(t)
                        // print("\(m) matched \(t)")
                    }
                    
                    let index = content.index(content.startIndex, offsetBy: m[0].count)
                    content = String(content[index...])
                    matched = true
                    break
                }
            }
            
            if !matched {
                let index = content.index(content.startIndex, offsetBy: 1)
                let o = String(content[...index]).trimmingCharacters(in: CharacterSet.whitespaces)
                tokens.append(.Other(o))
                // ToDo: handle error properly
                print("ignoring unrecognized token: \(o)")
                content = String(content[index...])
            }
        }
        return tokens
    }
}
