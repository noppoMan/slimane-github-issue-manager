//
//  ChatRoute.swift
//  GithubIssueManager
//
//  Created by Yuki Takei on 5/31/16.
//
//

import WS
import SwiftRedis


extension Redis {
    public static func publish(_ connection: SwiftRedis.Connection, channel: String, data: String,  callback: (SwiftRedis.GenericResult<Any>) -> ()) {
        Redis.command(connection, command: .RAW(["PUBLISH", channel, data]), completion: callback)
    }
    
    public static func subscribe(_ connection: SwiftRedis.Connection, channel: String, callback: (SwiftRedis.GenericResult<Any>) -> ()) {
        
        
        
        Redis.command(connection, command: .RAW(["SUBSCRIBE", channel]), completion: callback)
    }
    
    public static func unsubscribe(_ connection: SwiftRedis.Connection, channel: String, callback: (SwiftRedis.GenericResult<Any>) -> ()) {
        Redis.command(connection, command: .RAW(["UNSUBSCRIBE", channel]), completion: callback)
    }
}


private var sockets = [WebSocket]()

extension WebSocket {
    func unmanaged() -> Unmanaged<WebSocket> {
        sockets.append(self)
        return Unmanaged.passRetained(self)
    }
    
    func release(_ unmanaged: Unmanaged<WebSocket>){
        if let index = sockets.index(of: self) {
            sockets.remove(at: index)
            unmanaged.release()
        }
        // release strong ref and deinit will be called
        unmanaged.release()
    }
    
    func broadCast(to channel: String, with data: String){
        Redis.publish(redisPubConnection, channel: channel, data: data) { _ in }
    }
}


var subscribedChannels = [String]()

struct ChatRoute {
    static func websocketHandler(to request: Request, responder: ((Void) throws -> Response) -> Void){
        guard let _repo = request.query["repo"].first, let repo = _repo,
            let _owner = request.query["owner"].first, let owner = _owner,
            let _number = request.query["number"].first, let number = _number
            else {
                return
        }
        
        responder {
            var response = Response()
            response.body = .asyncSender({ stream, _ in
                let channel = "\(owner)/.\(repo).\(number)"
                
                Redis.subscribe(redisSubConnection, channel: channel) { result in
                    if case .Success(let rep) = result {
                        guard let rep = rep as? [String] else {
                            return
                        }
                        do {
                            let content = rep[2]
                            let json = try JSONParser().parse(data: content.data)
                            for s in sockets {
                                //if s != socket {
                                    let json = JSONSerializer().serializeToString(json: json)
                                    s.send(json)
                                //}
                            }
                        } catch {
                            print(error)
                        }
                    }
                }
                
                
                _ = WebSocketServer(to: request, with: stream) {
                    do {
                        let socket = try $0()
                        
                        // retain strong ref
                        let unmanaged = socket.unmanaged()
                        
                        socket.onClose { status, _ in
                            print("closed")
                            socket.release(unmanaged)
                        }
                        
                        socket.onText { text in
                            do {
                                var json = try JSONParser().parse(data: text.data)
                                
                                guard let event = json["event"]?.string,
                                    let data = json["data"],
                                    let currentUser = request.currentUser
                                else {
                                    return
                                }
                                
                                switch event {
                                case "comment":
                                    GithubApiRequest(
                                        token: currentUser.accessToken,
                                        method: .post,
                                        resource: "/repos/\(owner)/\(repo)/issues/\(number)/comments",
                                        body: JSONSerializer().serialize(json: ["body": data["body"]!.string!])
                                        )
                                        .send()
                                        .then { response in
                                            if 200..<300 ~= response.statusCode {
                                                json["owner"] = JSON(owner)
                                                json["repo"] = JSON(repo)
                                                json["number"] = JSON(number)
                                                socket.broadCast(to: channel, with: JSONSerializer().serializeToString(json: json))
                                            } else {
                                                var response = response
                                                let bodyData = try! response.body.becomeBuffer()
                                                let json: JSON = ["event": "error", "data": "\(bodyData)"]
                                                socket.send(JSONSerializer().serializeToString(json: json))
                                            }
                                        }
                                        .failure { error in
                                            let json: JSON = ["event": "error", "data": JSON(["message": "\(error)"])]
                                            socket.send(JSONSerializer().serializeToString(json: json))
                                        }
                                    
                                default:
                                    print("Unkonow event")
                                }
                            } catch {
                                print(error)
                            }
                        }
                        
//                        socket.onBinary {
//                            socket.broadCast($0)
//                        }
                        
                        socket.onPing {
                            socket.pong($0)
                        }
                    } catch {
                        stream.send(Response(status: .badRequest, body: "\(error)").description+"\r\n".data) {_ in }
                    }
                }
            })
            
            return response
        }
    }
}