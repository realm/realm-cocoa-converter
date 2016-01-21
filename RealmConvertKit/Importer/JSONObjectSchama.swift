//
//  JSONObjectSchama.swift
//  RealmConvertKit
//
//  Created by Tim Oliver on 21/01/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

@objc(RLMJSONObjectSchema)
public class JSONObjectSchema : NSObject {
    public var objectClassName: String
    var properties: [JSONObjectSchema.Property] = []
    
    init(objectClassName: String) {
        self.objectClassName = objectClassName
        super.init()
    }
    
    func toJSON() -> [String: AnyObject] {
        let fields = properties.map { (property) -> [String: AnyObject] in
            return property.toJSON()
        }
        return ["fields": fields, "primaryKey": NSNull()]
    }
    
    struct Property {
        let column: UInt
        let originalName: String
        let name: String
        var type: PropertyType = .String
        var indexed: Bool = false
        var optional: Bool = false
        
        init(column: UInt, originalName: String, name: String) {
            self.column = column
            self.originalName = originalName
            self.name = name
        }
        
        func toJSON() -> [String: AnyObject] {
            var field = [String: AnyObject]()
            field["column"] = column
            field["originalName"] = originalName
            field["name"] = name
            field["type"] = "\(type)"
            field["indexed"] = indexed
            field["optional"] = optional
            
            return field
        }
    }
}

extension JSONObjectSchema : CustomDebugStringConvertible {
    
    override public var description: String {
        let data = try! NSJSONSerialization.dataWithJSONObject(toJSON() as NSDictionary, options: .PrettyPrinted)
        return NSString(data: data, encoding: NSUTF8StringEncoding) as! String
    }
    
    override public var debugDescription: String {
        return description
    }
    
}