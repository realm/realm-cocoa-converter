//
//  JSONSchema.swift
//  RealmConvertKit
//
//  Created by Tim Oliver on 21/01/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

@objc(RLMJSONSchema)
public class JSONSchema : NSObject {
    var schemas: [JSONObjectSchema] = []
    
    init(schemas: [JSONObjectSchema]) {
        super.init()
        self.schemas = schemas
    }
    
    func toJSON() -> [String: AnyObject] {
        var s = [String: AnyObject]()
        for schema in schemas {
            s[schema.objectClassName] = schema.toJSON()
        }
        return s
    }
}

extension JSONSchema : CustomDebugStringConvertible {
    
    override public var description: String {
        let data = try! NSJSONSerialization.dataWithJSONObject(toJSON() as NSDictionary, options: .PrettyPrinted)
        return NSString(data: data, encoding: NSUTF8StringEncoding) as! String
    }
    
    override public var debugDescription: String {
        return description
    }
    
}