import Foundation
import OctoKit

let token = ""
let config = TokenConfiguration(token)
let client = Octokit(config)
var me: User? = nil

func main() {
    login()
    var validOption = false
    repeat {
        validOption = true
        switch listOptions() {
        case "1": listRepos()
        case "2": listStarredRepos()
        case "3": generateGitSync()
//        case "4": cloneFromGitSync()
        case "0": logout()
        default :
            validOption = false
            print("That is not a valid task")
        }
    } while !validOption
}

func login() {
    var authenticated: Bool? = nil
    client.me { response in
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
}

func listOptions() -> String {
    print("\nPlease select a task:")
    print("  1. List your repositories")
    print("  2. List your starred repositories")
    print("  3. Generate git-sync file")
    print("  4. Clone from git-sync file")
    print("  0. Exit")
    return readLine()!
}

func listRepos() {
    var reposListed: Bool? = nil
    client.repositories { response in
        switch response {
        case .success(let repos):
            print(repos.filter({ $0.owner.login == me!.login! }).map { $0.cloneURL! })
            reposListed = true
        case .failure(let error):
            print(error)
            reposListed = false
        }
    }
    repeat {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
    } while reposListed == nil
}

func listStarredRepos() {
    var reposListed: Bool? = nil
    client.myStars { response in
        switch response {
        case .success(let repos):
            print(repos.map { $0.name! })
            reposListed = true
        case .failure(let error):
            print(error)
            reposListed = false
        }
    }
    repeat {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
    } while reposListed == nil
}

func getRepositories() -> [OctoKit.Repository] {
    var reposListed: Bool? = nil
    var repositories: [OctoKit.Repository] = []
    client.repositories { response in
        switch response {
        case .success(let repos):
//            print(repos.filter({ $0.owner.login == me!.login! }).map { $0.cloneURL! })
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
    return repositories.filter({ $0.owner.login == me!.login! })
}

func generateGitSync() {
    
    /// Check if 'git-sync.json' exists in current directory
    let filePath = FileManager.default.currentDirectoryPath + "/git-sync.json"
//    print(filePath)  // DEBUG
    let fileReachable = FileManager.default.fileExists(atPath: filePath)
    
    /// If 'git-sync.json' exists, ask to overwrite (destructive)
    if fileReachable {
        print("WARNING: A git-sync configuration file already exists in this directory.")
        print("         Generating a new file is a destructive operation that will erase")
        print("         any previous settings. Would you like to continue? (y/N): ", terminator: "")
        switch readLine()! {
        case "y": break
        default : logout()
        }
    }
    
    /// Get all user repositories and create basic 'git-sync.json'
    let repositories = getRepositories()
    let repos: [Repo] = repositories.map { Repo(name: $0.name!, link: $0.cloneURL!, hidden: false) }
    let rootDirectory = Directory(name: "", subdirs: [], repositories: repos)
    let encoder = JSONEncoder()
    let data = try! encoder.encode(rootDirectory)
    let string = String(data: data, encoding: .utf8)!
    
    /// Write file to current directory (destructive)
    do {
        try string.write(toFile: filePath, atomically: false, encoding: .utf8)
    } catch {
        print("ERROR: Unable to create git-sync.json.")
        logout()
    }
    
    print("SUCCESS: A default git-sync configuration file has been generated for you.")
    logout()
}

func logout() {
    exit(0)
}

while true {
    main()
}
