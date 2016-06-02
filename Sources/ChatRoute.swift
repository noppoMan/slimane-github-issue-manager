//
//  ChatRoute.swift
//  GithubIssueManager
//
//  Created by Yuki Takei on 5/31/16.
//
//

import WS
import SwiftRedis
import Foundation

private var sockets = [WebSocket]()

func uuid() -> String {
    #if os(Linux)
        return NSUUID().UUIDString
    #else
        return NSUUID().uuidString
    #endif
}

extension WebSocket {
    var id: String? {
        return storage["id"] as? String
    }
    
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
    
    func broadcast(to channel: String, with json: JSON){
        var json = json
        json["session_id"] = JSON(self.id!)
        Redis.publish(redisPubConnection, channel: channel, data: JSONSerializer().serializeToString(json: json)) { _ in }
    }
    
    func send(json: JSON) {
        var json = json
        json["session_id"] = JSON(self.storage["id"] as! String)
        send(JSONSerializer().serializeToString(json: json))
    }
}

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
                
                _ = WebSocketServer(to: request, with: stream) {
                    do {
                        let socket = try $0()
                        
                        socket.storage["id"] = uuid()
                        
                        // retain strong ref
                        let unmanaged = socket.unmanaged()
                        
                        Redis.subscribe(redisSubConnection, channel: channel) { result in
                            if case .Success(let rep) = result {
                                guard let rep = rep as? [String] else {
                                    return
                                }
                                do {
                                    let content = rep[2]
                                    let json = try JSONParser().parse(data: content.data)
                                    for s in sockets {
                                        guard let id = json["session_id"]?.string, socketId = s.id else {
                                            continue
                                        }
                                        
                                        if id != socketId {
                                            s.send(json: json)
                                        }
                                    }
                                } catch {
                                    print(error)
                                }
                            }
                        }
                        
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
                                                socket.broadcast(to: channel, with: json)
                                            } else {
                                                var response = response
                                                let bodyData = try! response.body.becomeBuffer()
                                                let json: JSON = ["event": "error", "data": "\(bodyData)"]
                                                socket.send(json: json)
                                            }
                                        }
                                        .failure { error in
                                            let json: JSON = ["event": "error", "data": JSON(["message": "\(error)"])]
                                            socket.send(json: json)
                                        }
                                    
                                default:
                                    print("Unkonow event")
                                }
                            } catch {
                                print(error)
                            }
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