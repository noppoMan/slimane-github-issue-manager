//
//  AuthenticationMiddleware.swift
//  GithubIssueManager
//
//  Created by Yuki Takei on 5/29/16.
//
//

import SwiftRedis

extension Request {
    var isAuthenticated: Bool {
        return self.currentUser != nil
    }
    
    var currentUser: User? {
        get {
            return storage["currentUser"] as? User
        }
        
        set {
            return storage["currentUser"] = newValue
        }
    }
    
    func logout() {
        session?.destroy()
    }
}

func authenticationMiddleware(req: Request, res: Response, next: MiddlewareChain) {
    var req = req
    
    if let currentUser = req.session?["currentUser"] as? String {
        do {
            let json = try JSONParser().parse(data: currentUser.data)
            req.currentUser = try User(json: json)
        } catch {
            next(.Error(error))
            return
        }
    }
    
    if req.isAuthenticated {
        return next(.Chain(req, res))
    }
    
    if req.path == "/auth/callback/github" {
        if let _code = req.query["code"].first, let code = _code {
            getAccessToken(code: code)
                .then(getUserInfo)
                .then { (user: User?) in
                    if let user = user {
                        req.session?["currentUser"] = user.serialize() as AnyObject
                        let t = Timer(tick: 1000)
                        t.start {
                            t.end()
                            next(.Intercept(req, Response(redirect: "\(APP_BASE_URL)/")))
                        }
                    } else {
                        next(.Error(Error.AuthenticationFailed))
                    }
                }
                .failure {
                    next(.Error($0))
            }
        } else {
            next(.Error(Error.AuthenticationFailed))
        }
    }
    else if req.path != "/auth" {
        next(.Intercept(req, Response(redirect: "\(APP_BASE_URL)/auth")))
    }
    else {
        next(.Chain(req, res))
    }
}

private func getAccessToken(code: String) -> Promise<String> {
    let body = [
                   "client_id": GITHUB_CLIENT_ID,
                   "client_secret": GITHUB_CLIENT_SECRET,
                   "code": code,
                   "redirect_uri": "\(APP_BASE_URL)/auth/callback/github",
                   "accept": "application/json"
        ]
        .map({ k, v in "\(k)=\(v)" })
        .joined(separator: "&")
    
    return RestClient(
            method: .post,
            uri: "\(GITHUB_AUTH_BASE_URL)/login/oauth/access_token",
            body: body.data
        )
        .send()
        .then { (response: Response) -> Promise<String> in
            if let data = response.formData, let accessToken = data["access_token"] {
                return Promise<String>.resolve(accessToken)
            }
            return Promise<String>.reject(Error.AuthenticationFailed)
        }
}

private func getUserInfo(accessToken: String) -> Promise<User?> {
    return RestClient(
        method: .get,
        uri: "\(GITHUB_API_BASE_URL)/user?access_token=\(accessToken)"
        )
        .send()
        .then { (response: Response) -> Promise<User?> in
            guard var json = response.jsonData else {
                return Promise<User?>.reject(Error.AuthenticationFailed)
            }
            
            json["access_token"] = JSON(accessToken)
            
            do {
                let user = try User(json: json)
                return Promise<User?>.resolve(user)
            } catch {
                return Promise<User?>.reject(error)
            }
    }
}