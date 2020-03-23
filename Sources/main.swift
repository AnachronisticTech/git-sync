//
//  main.swift
//  git-sync
//
//  Created by Daniel Marriner on 17/12/2019.
//

import Foundation
import OctoKit
import SwiftGit2
import libgit2
import KeychainAccess

var username = ""
var password = ""

var client: Octokit? = nil
var me: User? = nil

func main() {
    git_libgit2_init()
    let args = ["init", "update", "pull", "setup"]
    if args.filter({ CommandLine.arguments.contains($0) }).count > 1 {
        print("Error: Too many arguments passed.")
        exit(1)
    } else if CommandLine.arguments.count == 1 {
        login()
        cloneFromGitSync()
    } else {
        switch CommandLine.arguments[1] {
        case "init":
            login()
            generateGitSync()
        case "update":
            login()
            updateGitSync()
        case "setup":
            setup(with: CommandLine.arguments[2])
        default:
            login()
            cloneFromGitSync()
        }
    }
}

func login() {
    let tokens = Keychain(service: "git-sync").allKeys()
    if tokens.count == 0 {
        print("ERROR: No access token was found. Please run git-sync setup <token>.")
        // Maybe add link explaining how to get a token
        exit(1)
    } else {
        let token = try! Keychain(service: "git-sync").get(tokens[0])!
        let config = TokenConfiguration(token)
        client = Octokit(config)
    
        var authenticated: Bool? = nil
        client!.me { response in
            switch response {
            case .success(let user):
                print("Welcome to git-sync, \(user.login!)")
                me = user
                authenticated = true
            case .failure(let error):
                print(error)
                authenticated = false
            }
        }
        repeat {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        } while authenticated == nil
        if !authenticated! {
            exit(1)
        }
        let gitTokens = Keychain(server: URL(string: "github.com")!, protocolType: .https).allKeys()
        if gitTokens.count == 0 {
            print("ERROR: No Git credentials were found. Would you like to enter them now? [y/N]", terminator: "")
            switch readLine()! {
            case "y": break
            default : exit(1)
            }
            print("Username: ", terminator: "")
            username = readLine()!
            print("Password: ", terminator: "")
            password = readLine()!
            let chain = Keychain(server: URL(string: "github.com")!, protocolType: .https)
            chain[username] = password
            print("SUCCESS: Git credentials saved successfully.")
        } else {
            username = gitTokens[0]
            password = try! Keychain(server: URL(string: "github.com")!, protocolType: .https).get(gitTokens[0])!
        }
    }
}

func setup(with token: String) {
    let chain = Keychain(service: "git-sync")
    chain["token"] = token
    print("SUCCESS: Token saved successfully.")
}

func getRepositories() -> [OctoKit.Repository] {
    var reposListed: Bool? = nil
    var repositories: [OctoKit.Repository] = []
    client!.repositories { response in
        switch response {
        case .success(let repos):
            repositories = repos
            reposListed = true
        case .failure(let error):
            print(error)
            reposListed = false
        }
    }
    repeat {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
    } while reposListed == nil
    
    /// Return non-organisation repositories
    return repositories.filter({ $0.owner.login == me!.login! })
}

func generateGitSync() {
    
    /// Check if '.git-sync' exists in current directory
    let filePath = FileManager.default.currentDirectoryPath + "/.git-sync"
//    print(filePath)  // DEBUG
    let fileReachable = FileManager.default.fileExists(atPath: filePath)
    
    /// If '.git-sync' file exists, ask to overwrite (destructive)
    if fileReachable {
        print("WARNING: A git-sync configuration file already exists in this directory.")
        print("         Generating a new file is a destructive operation that will erase")
        print("         any previous settings. Would you like to continue? (y/N): ", terminator: "")
        switch readLine()! {
        case "y": break
        default : exit(0)
        }
    }
    
    /// Get all user repositories and create basic '.git-sync' file
    let repositories = getRepositories()
    let repos: [Repo] = repositories.map { Repo(name: $0.name!, link: $0.cloneURL!, hidden: false) }
    let rootDirectory = Root(subdirs: [], repositories: repos)
    let encoder = JSONEncoder()
    let data = try! encoder.encode(rootDirectory)
    let string = String(data: data, encoding: .utf8)!
    
    /// Write file to current directory (destructive)
    do {
        try string.write(toFile: filePath, atomically: false, encoding: .utf8)
    } catch {
        print("ERROR: Unable to create git-sync configuration file.")
        exit(1)
    }
    
    print("SUCCESS: A default git-sync configuration file has been generated for you.")
    exit(0)
}

func updateGitSync() {
            
    /// Check if '.git-sync' exists in current directory
    let filePath = FileManager.default.currentDirectoryPath + "/.git-sync"
    let fileReachable = FileManager.default.fileExists(atPath: filePath)
    
    /// If '.git-sync' doesn't exist, ask to try again later
    if !fileReachable {
        print("ERROR: No git-sync configuration file exists in this directory. Please")
        print("       make sure you are in the correct directory, or run git-sync init")
        print("       to generate a default one.")
        exit(1)
    }
    
    /// Read '.git-sync' file
    let file = FileHandle(forReadingAtPath: filePath)!
    let data = file.readDataToEndOfFile()
    file.closeFile()
    
    /// Decode file contents into data structure
    let decoder = JSONDecoder()
    var structure: Root
    do {
        structure = try decoder.decode(Root.self, from: data)
    } catch {
        print("ERROR: Unable to interpret git-sync configuration file.")
        exit(1)
    }
    
    /// Compare '.git-sync' with list of repositories and add missing to root directory
    let gitSyncRepos = structure.flatten()
    let gitHubRepos = getRepositories().map { Repo(name: $0.name!, link: $0.cloneURL!, hidden: false) }
    gitHubRepos.forEach{ repo in
        if !gitSyncRepos.contains(repo) {
            structure.repositories.append(repo)
        }
    }
    
    /// Generate updated '.git-sync'
    let encoder = JSONEncoder()
    let newData = try! encoder.encode(structure)
    let string = String(data: newData, encoding: .utf8)!
    
    /// Write file to current directory (destructive)
    do {
        try string.write(toFile: filePath, atomically: false, encoding: .utf8)
    } catch {
        print("ERROR: Unable to write updated git-sync configuration file.")
        exit(1)
    }
    
    print("SUCCESS: Your git-sync configuration file has been updated.")
    exit(0)
}

func cloneFromGitSync() {
        
    /// Check if '.git-sync' exists in current directory
    let filePath = FileManager.default.currentDirectoryPath + "/.git-sync"
//    print(filePath)  // DEBUG
    let fileReachable = FileManager.default.fileExists(atPath: filePath)
    
    /// If '.git-sync' doesn't exist, ask to try again later
    if !fileReachable {
        print("ERROR: No git-sync configuration file exists in this directory. Please")
        print("       make sure you are in the correct directory, or run git-sync init")
        print("       to generate a default one.")
        exit(1)
    }
    
    /// Read '.git-sync' file
    let file = FileHandle(forReadingAtPath: filePath)!
    let data = file.readDataToEndOfFile()
    file.closeFile()
    
    /// Decode file contents into data structure
    let decoder = JSONDecoder()
    let structure: Root
    do {
        structure = try decoder.decode(Root.self, from: data)
    } catch {
        print("ERROR: Unable to interpret git-sync configuration file.")
        exit(1)
    }
    
    /// Create directory structure and clone non-hidden repositories
    structure.create()
    
    exit(0)
}

main()
