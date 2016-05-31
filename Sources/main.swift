@_exported import Slimane
@_exported import Render
@_exported import BodyParser
@_exported import SessionMiddleware
@_exported import HTTP
@_exported import Thrush
@_exported import JSON
@_exported import QWFuture
import SwiftRedis

let redisConnection = try! SwiftRedis.Connection(loop: Loop.defaultLoop.loopPtr, host: "127.0.0.1", port: 6379)
let redisPubConnection = try! SwiftRedis.Connection(loop: Loop.defaultLoop.loopPtr, host: "127.0.0.1", port: 6379)
let redisSubConnection = try! SwiftRedis.Connection(loop: Loop.defaultLoop.loopPtr, host: "127.0.0.1", port: 6379)

let app = Slimane()

do {
    app.use(Slimane.Static(root: Process.cwd + "/public"))

    app.use(BodyParser())
    
    app.use(SessionMiddleware(conf: try sessionConfig()))

    // authorization middleware
    app.use(authenticationMiddleware)
    
    // api group
    do {
        app.post("/api/:owner/:repo/issues") { req, responder in
            guard let json = req.json else {
                return responder {
                    Response(status: .badRequest, body: "Request body should be a correct JSON")
                }
            }
            
            GithubApiRequest(
                token: req.currentUser!.accessToken,
                method: .post,
                resource: "/repos/\(req.params["owner"]!)/\(req.params["repo"]!)/issues",
                body: JSONSerializer().serialize(json: json)
                )
                .send()
                .then { response in
                    responder {
                        if 200..<300 ~= response.statusCode {
                            return Response(status: .created, json: response.jsonData!)
                        } else {
                            return Response(status: .badRequest, json: response.jsonData!)
                        }
                    }
                }
                .failure { error in
                    responder {
                        let json: JSON = ["error": "\(error)"]
                        return Response(status: .badRequest, json: json)
                    }
                }
        }
    }
    
    // web page group
    do {
        app.get("/auth") { req, responder in
            responder {
                if req.isAuthenticated {
                    return Response(redirect: "\(APP_BASE_URL)/")
                } else {
                    return Response.render("auth/index", data: ["clientId": GITHUB_CLIENT_ID])
                }
            }
        }
        
        app.get("/issues/:owner/:repo") { req, responder in
            responder {
                let data = [
                    "owner": req.params["owner"]!,
                    "repo": req.params["repo"]!,
                    "currentUser": req.currentUser!.serialize()
                ]
                return Response.render("/issues/index", data: data)
            }
        }
        
        app.get("/issues/:owner/:repo/new") { req, responder in
            responder {
                let data = [
                    "owner": req.params["owner"]!,
                    "repo": req.params["repo"]!,
                    "currentUser": req.currentUser!.serialize()
                ]
                return Response.render("/issues/new", data: data)
            }
        }
        
        app.get("/issues/:owner/:repo/:number") { req, responder in
            responder {
                let data = [
                    "owner": req.params["owner"]!,
                    "repo": req.params["repo"]!,
                    "number": req.params["number"]!,
                    "currentUser": req.currentUser!.serialize()
                ]
                return Response.render("/issues/show", data: data)
            }
        }
        
        app.get("/issues/:owner/:repo/:number/edit") { req, responder in
            responder {
                let data = [
                    "owner": req.params["owner"]!,
                    "repo": req.params["repo"]!,
                    "number": req.params["number"]!,
                    "currentUser": req.currentUser!.serialize()
                ]
                return Response.render("/issues/edit", data: data)
            }
        }
        
        app.get("/logout") { req, responder in
            req.logout()
            responder {
                Response(redirect: "\(APP_BASE_URL)/")
            }
        }

        app.get("/") { req, responder in
            responder {
                Response.render("index", data: ["currentUser": req.currentUser!.serialize()])
            }
        }
    }
    
    // websocket group
    do {
        app.get("/ws/chat", handler: ChatRoute.websocketHandler)
    }

    print("Server started up at 0.0.0.0:\(PORT)")
    try app.listen(port: PORT)
    
} catch {
    print(error)
}