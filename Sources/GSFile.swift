//
//  GSFile.swift
//  git-sync
//
//  Created by Daniel Marriner on 26/03/2020.
//  Copyright © 2020 Daniel Marriner. All rights reserved.
//

import Foundation

struct GSFile: Codable, Checkable {
    let remotes: [GSRemote]
    let subdirectories: [GSDirectory]
    var repositories: [GSRepository]
}

extension GSFile {
    func create() {
        /// Reset directory stack
        directoryStack = ["/"]
        
        /// Check if directory structure matches git-sync file
        if !checkDir() {
            return
        }
        
        /// Check for local directory naming conflicts
        if containsNameConflict() {
            print("ERROR: A directory contains folders or repositories with duplicate")
            print("       names. Please correct your git-sync configuration file and")
            print("       try again.")
            return
        }
        
        /// Create sub-directories recursively
        self.subdirectories.forEach { $0.create() }
        
        /// Clone repositories in this directory
        self.repositories.forEach { $0.create() }
    }
    
    func checkDir() -> Bool {
        /// Reset directory stack
        directoryStack = ["/"]
        
        /// Get contents of current directory
        let directoryContents: [String]
        do {
            directoryContents = try FileManager.default.contentsOfDirectory(atPath: currentDirectory + directoryStack.last!).filter({ !directoryBlacklist.contains($0) }).sorted()
        } catch {
            print("ERROR: Unable to read contents of directory.")
            return false
        }
        let gitSyncDirContents = (self.subdirectories.map({ $0.name }) + self.repositories.filter({ $0.visible }).map({ $0.name })).sorted()
        
        /// Check if directory contents contain any .git-sync contents
        if directoryContents.containsAny(ofElementsIn: gitSyncDirContents) {
            print("ERROR: Directory contains some git-sync folders that would be")
            print("       overwritten. Please check the folder structure matches")
            print("       your git-sync configuration file and try again.")
            return false
        }
        
        /// Directory clear for creating structure and cloning repositories
        return true
    }
    
    func write() -> String {
        var arr = [String]()
        self.remotes.forEach { remote in
            arr.append("using \"\(remote.url)\" as \(remote.identifier)\n")
        }
        arr.append("\n")
        self.subdirectories.forEach { dir in
            arr.append(dir.write(with: 0) + "\n")
        }
        self.repositories.forEach { repo in
            arr.append(repo.write(with: 0) + "\n")
        }
        return arr.string()
    }
}
