import Foundation
import OctoKit

let token = ""
let config = TokenConfiguration(token)
let client = Octokit(config)
var me: User? = nil

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
