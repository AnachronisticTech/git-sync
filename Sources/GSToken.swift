//
//  GSToken.swift
//  git-sync
//
//  Created by Daniel Marriner on 25/03/2020.
//  Copyright © 2020 Daniel Marriner. All rights reserved.
//

import Foundation

enum GSToken {
    typealias Generator = (String) -> GSToken?
    
    case using
    case `as`
    case `in`
    case visibility(String)
    case openBrace
    case closeBrace
    case quote
    case identifier(String)
    
    static var generators: [String: Generator] {
        return [
            "\\{": { _ in .openBrace },
            "\\}": { _ in .closeBrace },
            "\"": { _ in .quote },
            "[a-zA-Z0-9\\-\\+_.:/]+": { .identifier($0) }
        ]
    }
}
