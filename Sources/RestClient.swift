//
//  RestClient.swift
//  GithubIssueManager
//
//  Created by Yuki Takei on 5/29/16.
//
//

import CCurl
import Foundation
import HTTPParser

struct CurlContext {
    let writeCallback: ([Byte]) -> ()
}

extension String {
    var buffer: UnsafePointer<Int8>? {
        return NSString(string: self).utf8String
    }
}

extension Response {
    var jsonData: JSON? {
        get {
            return storage["json"] as? JSON
        }
        
        set {
            storage["json"] = newValue
        }
    }
    
    public var formData: URLEncodedForm? {
        get {
            return self.storage["formData"] as? URLEncodedForm
        }
        
        set {
            self.storage["formData"] = newValue
        }
    }
}

struct RestClient {
    
    enum Error: ErrorProtocol {
        case ParserFailure
    }
    
    let method: S4.Method
    
    let uri: String
    
    let headers: Headers
    
    let body: Data
    
    let loop: Loop
    
    init(loop: Loop = Loop.defaultLoop, method: S4.Method, uri: String, headers: Headers = [:], body: Data = []){
        var headers = headers
        if headers["User-Agent"].isEmpty {
           headers["User-Agent"] = "Slimane-Curl-Client"
        }
        
        self.loop = loop
        self.method = method
        self.uri = uri
        self.headers = headers
        self.body = body
    }
    
    func send() -> Promise<Response> {
        return Promise<Response> { resolve, reject in
            let future = QWFuture<Response>(loop: self.loop) { (completion: (() throws -> Response) -> ()) in
                let handle = curl_easy_init()
                curlHelperSetOptString(handle, CURLOPT_URL, UnsafeMutablePointer(self.uri.buffer))
                
                switch self.method {
                case .post:
                    curlHelperSetOptBool(handle, CURLOPT_POST, CURL_TRUE)
                default:
                    curlHelperSetOptBool(handle, CURLOPT_HTTPGET, CURL_TRUE)
                }
                
                if !self.body.isEmpty {
                    curlHelperSetOptString(handle, CURLOPT_POSTFIELDS, UnsafeMutablePointer("\(self.body)".buffer))
                    curlHelperSetOptInt(handle, CURLOPT_POSTFIELDSIZE, self.body.bytes.count)
                }
                
                
                var headersList: UnsafeMutablePointer<curl_slist>? = nil
                
                if !self.headers.isEmpty {
                    for (key, value) in self.headers {
                        headersList = curl_slist_append(headersList, UnsafeMutablePointer<Int8>("\(key): \(value)".buffer))
                    }
                    curlHelperSetOptHeaders(handle, headersList)
                }
                
                let context = UnsafeMutablePointer<CurlContext>(allocatingCapacity: 1)
                
                defer {
                    context.deinitialize()
                    context.deallocateCapacity(1)
                }
                
                var data = Data()
                
                let writeCallback = { (bytes: [Byte]) in
                    data.append(contentsOf: bytes)
                }
                
                context.initialize(with: CurlContext(writeCallback: writeCallback))
                
                curlHelperSetOptWriteFunc(handle, context) { (buf: UnsafeMutablePointer<Int8>?, size: Int, nMemb: Int,  privateData: UnsafeMutablePointer<Void>?) -> Int in
                    
                    let ctx = UnsafePointer<CurlContext?>(privateData)
                    
                    let segsize = size * nMemb
                    
                    var bytes = [Byte]()
                    
                    for i in stride(from: 0, to: segsize, by: 1) {
                        bytes.append(Byte(bitPattern: buf![i]))
                    }
                    
                    ctx?.pointee?.writeCallback(bytes)
                    
                    return segsize
                }
                
                // perform and cleanup
                curl_easy_perform(handle)
                
                completion {
                    defer {
                        curl_easy_cleanup(handle)
                    }
                    
                    var status = 0
                    curlHelperGetInfoLong(handle, CURLINFO_RESPONSE_CODE, &status)
                    
                    // retry manually parse
                    let splitedResponseString = "\(data)".split(byString: "\r\n\r\n")
                    guard splitedResponseString.count >= 2 else {
                        throw Error.ParserFailure
                    }
                    
                    var currentPhrase = ""
                    var sawHeadlines = false
                    var headers: Headers = [:]
                    
                    splitedResponseString[0].characters.forEach {
                        if $0 == "\r\n" {
                            if !sawHeadlines {
                                sawHeadlines = true
                            } else {
                                let splited = currentPhrase.split(separator: ":")
                                headers[splited[0]] = Header(splited[1].trim())
                            }
                            currentPhrase = ""
                            return
                        }
                        currentPhrase.append($0)
                    }
                    
                    let body = splitedResponseString[1]
                    
                    var response = Response(status: Status(statusCode: status), headers: headers, body: body.data)
                    if let contentType = response.contentType {
                        switch (contentType.type, contentType.subtype) {
                        case ("application", "json"):
                            response.jsonData = try JSONParser().parse(data: body.data)
                        case ("application", "x-www-form-urlencoded"):
                            response.formData = try URLEncodedFormParser().parse(body.data)
                        default:
                            print("Unkown Content-Type.")
                        }
                    }
                    
                    return response
                }
            }
            
            future.onSuccess {
                resolve($0)
            }
            
            future.onFailure {
                reject($0)
            }
        }
    }
}
