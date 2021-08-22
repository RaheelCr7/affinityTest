//
//  ImageModel.swift
//  DemoAf
//
//  Created by Raheel Rehman on 22/08/2021.
//

import Foundation

struct ImageModel {
    
    // Json keys
    static let SENDER_KEY = "sender"
    static let MESSAGE_KEY = "message"
    static let TIMESTAMP_KEY = "timestamp"
    static let IMAGE_KEY = "image"
    
    // Sender values
    static let SERVER_MSG_SENDER = "SERVER_MSG_SENDER"
    static let SERVER_NAME_SENDER = "SERVER_NAME_SENDER"
    
    let sender: String
    let message: String
    let timestamp: Date
    let image: String
    
    
    init(sender: String, message: String, timestamp: Date, image: String) {
        self.sender = sender
        self.message = message
        self.timestamp = timestamp
        self.image = image
    }
    
    init(jsonData: Data) throws {
        var sender = ""
        var message = ""
        var image = ""
        var timestamp = Date()
        if let dict = try JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves) as? NSDictionary {
            sender = dict[ImageModel.SENDER_KEY] as? String ?? ""
            message = dict[ImageModel.MESSAGE_KEY] as? String ?? ""
            image = dict[ImageModel.IMAGE_KEY] as? String ?? ""
            if let interval = dict[ImageModel.TIMESTAMP_KEY] as? TimeInterval {
                timestamp = Date(timeIntervalSince1970: interval / 1000)
            }
        }
        self.sender = sender
        self.message = message
        self.timestamp = timestamp
        self.image = image
    }
    
    init(dict: Dictionary<String, Any>) {
        self.sender = dict[ImageModel.SENDER_KEY] as? String ?? ""
        self.message = dict[ImageModel.MESSAGE_KEY] as? String ?? ""
        self.image = dict[ImageModel.IMAGE_KEY] as? String ?? ""
        if let interval = dict[ImageModel.TIMESTAMP_KEY] as? TimeInterval {
            self.timestamp = Date(timeIntervalSince1970: interval)
        } else {
            self.timestamp = Date()
        }
    }
    
    func toDict() -> Dictionary<String, Any> {
        var dict = Dictionary<String, Any>()
        dict[ImageModel.SENDER_KEY] = self.sender
        dict[ImageModel.MESSAGE_KEY] = self.message
        dict[ImageModel.IMAGE_KEY] = self.image
        dict[ImageModel.TIMESTAMP_KEY] = (Int) (self.timestamp.timeIntervalSince1970 * 1000)
        return dict
    }
    
    func toJsonData() throws -> Data {
        return try JSONSerialization.data(withJSONObject: toDict(), options: .fragmentsAllowed)
    }
}

extension Array {
    static func messagesFromJsonData(_ jsonData: Data) throws -> [ImageModel] {
        var messages: [ImageModel] = []
        if let array = try JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves) as? NSArray {
            for case let dict as Dictionary<String, Any> in array {
                messages.append(ImageModel(dict: dict))
            }
        }
        return messages
    }
    
    func messagesToJsonData() throws -> Data {
        var jsonArray: [Dictionary<String, Any>] = []
        for case let message as ImageModel in self {
            jsonArray.append(message.toDict())
        }
        return try JSONSerialization.data(withJSONObject: jsonArray, options: .fragmentsAllowed)
    }
}
