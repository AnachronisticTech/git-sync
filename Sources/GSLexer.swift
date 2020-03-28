//
//  GSLexer.swift
//  git-sync
//
//  Created by Daniel Marriner on 25/03/2020.
//  Copyright © 2020 Daniel Marriner. All rights reserved.
//

import Foundation

class GSLexer {
    let tokens: [GSToken]
    
    private static func getNextPrefix(code: String) -> (regex: String, prefix: String)? {
        let keyValue = GSToken.generators.first(where: { regex, generator in
            code.getPrefix(regex: regex) != nil
        })
        guard let regex = keyValue?.key, keyValue?.value != nil else {
            return nil
        }
        return (regex, code.getPrefix(regex: regex)!)
    }
    
    init(code: String) {
        var code = code
        code.trimLeadingWhitespace()
        var tokens: [GSToken] = []
        while let next = GSLexer.getNextPrefix(code: code) {
            let (regex, prefix) = next
            code = String(code[prefix.endIndex...])
            code.trimLeadingWhitespace()
            guard let generator = GSToken.generators[regex], let token = generator(prefix) else {
                fatalError()
            }
            tokens.append(token)
        }
        tokens = tokens.map { token in
            if case let .identifier(string) = token {
                switch string {
                case "using": return .using
                case "as": return .as
                case "in": return .in
                case "-": return .visibility("-")
                case "+": return .visibility("+")
                default: return token
                }
            } else {
                return token
            }
        }
        self.tokens = tokens
    }
}
