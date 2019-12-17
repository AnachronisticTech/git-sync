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
//        case "1": listRepos()
//        case "2": listStarredRepos()
//        case "3": generateGitSync()
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

func logout() {
    exit(0)
}

while true {
    main()
}
