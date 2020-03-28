//
//  GSRepository.swift
//  git-sync
//
//  Created by Daniel Marriner on 25/03/2020.
//  Copyright © 2020 Daniel Marriner. All rights reserved.
//

import Foundation
import SwiftGit2

struct GSRepository: Codable, Equatable {
    let name: String
    let domain: String
    let visible: Bool
    
    static func == (lhs: GSRepository, rhs: GSRepository) -> Bool {
        return remotes[lhs.domain] == remotes[rhs.domain] && lhs.name == rhs.name
    }
}

extension GSRepository {
    func create() {
        /// If repository not marked as hidden, clone into current directory with name
        if self.visible {
            print("Cloning \(self.name) into \(directoryStack.last!)\(self.name)")
            try? FileManager.default.createDirectory(atPath: currentDirectory + directoryStack.last! + "/\(self.name)", withIntermediateDirectories: true, attributes: nil)
            var url: URL? = nil
            if let link = remotes[self.domain] {
                url = URL(string: "\(link)/\(self.name)")
            }
            if let url = url {
                let _ = Repository.clone(from: url, to: URL(string: currentDirectory + directoryStack.last! + "/\(self.name)")!, credentials: creds)
            }
        }
    }
    
    func write(with depth: Int) -> String {
        let indent = Array(repeating: "\t", count: depth)
        return "\(indent.string())\(self.visible ? "+" : "-") \(self.domain) \(self.name)"
    }
}
