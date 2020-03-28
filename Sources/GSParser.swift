//
//  GSParser.swift
//  git-sync
//
//  Created by Daniel Marriner on 23/03/2020.
//  Copyright © 2020 Daniel Marriner. All rights reserved.
//

import Foundation

class GSParser {
    enum Error: Swift.Error {
        case expectedKeyword(String)
        case expectedVisibility
        case expectedString
        case expectedBrace
        case expectedQuote
        case expectedRepoOrDirectory
    }
    
    let tokens: [GSToken]
    var index = 0
    var canPop: Bool { return index < tokens.count }
    
    init(tokens: [GSToken]) {
        self.tokens = tokens
    }
    
    private func peek() -> GSToken {
        return tokens[index]
    }
    
    private func popToken() -> GSToken {
        let token = tokens[index]
        index += 1
        return token
    }
    
    func parse() throws -> GSFile {
        var remotes: [GSRemote] = []
        while case .using = peek() {
            let remote = try parseUsingAs()
            remotes.append(remote)
        }
        var folders: [GSDirectory] = []
        var repos: [GSRepository] = []
        while canPop {
            switch peek() {
            case .in:
                let folder = try parseDirectory()
                folders.append(folder)
            case .visibility(_):
                let repo = try parseRepo()
                repos.append(repo)
            default:
                throw Error.expectedRepoOrDirectory
            }
        }
        return GSFile(remotes: remotes, subdirectories: folders, repositories: repos)
    }
    
    private func parseDirectory() throws -> GSDirectory {
        guard case .in = popToken() else {
            throw Error.expectedKeyword("in")
        }
        let name = try parseString()
        guard case .openBrace = popToken() else {
            throw Error.expectedBrace
        }
        var dirs: [GSDirectory] = []
        var repos: [GSRepository] = []
        
        outerLoop: while canPop {
            switch peek() {
            case .visibility(_):
                let repo = try parseRepo()
                repos.append(repo)
            case .in:
                let dir = try parseDirectory()
                dirs.append(dir)
            case .closeBrace:
                break outerLoop
            default:
                throw Error.expectedRepoOrDirectory
            }
        }
        
        guard case .closeBrace = popToken() else {
            throw Error.expectedBrace
        }
        return GSDirectory(name: name, subdirectories: dirs, repositories: repos)
    }
    
    private func parseRepo() throws -> GSRepository {
        let visibility = try parseVisibility()
        let identifier = try parseString()
        let name = try parseString()
        
        return GSRepository(name: name, domain: identifier, visible: visibility)
    }
    
    private func parseUsingAs() throws -> GSRemote {
        guard case .using = popToken() else {
            throw Error.expectedKeyword("using")
        }
        let url = try parseURL()
        guard case .as = popToken() else {
            throw Error.expectedKeyword("as")
        }
        let identifier = try parseString()
        
        return GSRemote(url: url, identifier: identifier)
    }
    
    private func parseURL() throws -> String {
        guard case .quote = popToken() else {
            throw Error.expectedQuote
        }
        let string = try parseString()
        guard case .quote = popToken() else {
            throw Error.expectedQuote
        }
        return string
    }
    
    private func parseString() throws -> String {
        guard case let .identifier(string) = popToken() else {
            throw Error.expectedString
        }
        return string
    }
    
    private func parseVisibility() throws -> Bool {
        guard case let .visibility(sym) = popToken() else {
            throw Error.expectedVisibility
        }
        return sym == "+"
    }
}
