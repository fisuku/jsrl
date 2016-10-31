//
//  Chat.swift
//  jsrl
//
//  Created by Fisk on 10/10/2016.
//  Copyright © 2016 fisk. All rights reserved.
//

import Foundation

class Chat : Resource {
    var recvEndpoint = "/chat/messages.xml"
    var sendEndpoint = "/chat/save.php"
    
    /**
     Fetch the latest chat messages in messages.xml.
     
     - properties:
    	- callback: Callback returning an Error (nil if OK) and an array of
     				ChatMessage responses.
 	 */
    func fetch(_ callback: @escaping (_ err: Error?, _ body: [ChatMessage])->()) {
        let url = URL(string: context.root + recvEndpoint)
        
        DispatchQueue.main.async {
            let parser = XMLParser(contentsOf: url!)!
            
            let chatParser = ChatParser()
            parser.delegate = chatParser
            parser.parse()
            
            print(chatParser.messages.count)
            
            callback(nil, chatParser.messages)
        }
    }
    
    /**
     Post a message to the chat.
     
     - properties:
     	- message: A ChatMessage.
    	- callback: Callback returning an Error (nil if OK) and an URLResponse.
     */
    func send(_ message: ChatMessage, _ callback: @escaping (_ err: Error, _ response: URLResponse)->()) {
        let url = URL(string: context.root + sendEndpoint)
        
        let form: [String: String] = [
            "chatmessage": message.text,
            "chatpassword": message.password ? "true" : "false",
            "username": message.username
        ]
        
        let formData = form.map({"\($0)=\($1.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed))"}).joined(separator: "&")
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        request.httpBody = formData.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            (data, response, error) in
            
            guard let data = data, let _:URLResponse = response  , error == nil else {
                print("error")
                return
            }
            
            let dataString =  String(data: data, encoding: String.Encoding.utf8)
            print(dataString ?? "")
            
//            callback("", dataString!)
        }
        
        task.resume()
    }
}

/**
 A class that wraps the chat API and creates a tailing event-based handler, emulating a stream of messages.
 Don't forget to clear clearHandlers() when done.
 */
class ChatTail {
    let chat: Chat
    var previousMessages: [ChatMessage] = []
    var handlers = [(ChatMessage) -> ()]()
    
    init (_ chat: Chat) {
        self.chat = chat
    }
    
    func invokeFetch() {
        self.chat.fetch({(err, newMessages: [ChatMessage]) in
            // create a union between old and new messages
            
            // Fetch the last message
            let last = self.previousMessages[self.previousMessages.count - 1]
            var startIndex = 0
            
            for i in 0...newMessages.count {
                if newMessages[i] == last {
                    startIndex = i
                    break
                }
            }
            
            // Send messages out to listeners
            for i in startIndex...newMessages.count {
                _ = self.handlers.map {
                    $0(newMessages[i])
                }
            }
            
            // Replace the previousMessages list
            self.previousMessages = newMessages
        })
    }
    
    func onMessageReceived(callback: @escaping (ChatMessage) -> ()) {
        self.handlers.append(callback)
    }
    
    func clearHandlers() {
        self.handlers.removeAll()
    }
}

/**
 An entity representing a single message digest.
 */
class ChatMessage: CustomStringConvertible {
    /**
     Message text.
     */
    var text: String = ""
    
    /**
     Usernames. May contain HTML
     */
    var username: String = ""
    
    /**
     is a 40-character hash, e.g. 250e7dd82f8dbba1e0463134ea4f7e3dcdb313e3
     
     It is unknown if this field is decryptable or not:
     - it's too long to be an md5 hash
     - doesn't seem to decode as hex or base64
     - is not referenced in the site's obfuscated javascript source
     */
    var ip: String = ""
    
    /**
     Not sure how this field works yet.
     */
    var password: Bool = false
    
    /**
     ChatMessage equality comparator
 	*/
    static func ==(left:ChatMessage, right: ChatMessage) -> Bool {
        return left.username == right.username && left.text == right.text
    }
    
    var description: String {
        return "[ChatMessage] \(username): \(text)"
    }
}