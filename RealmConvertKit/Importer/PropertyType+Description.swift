//
//  PropertyType+Description.swift
//  RealmConvertKit
//
//  Created by Tim Oliver on 21/01/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

extension PropertyType : CustomStringConvertible, CustomDebugStringConvertible {
    public var description: Swift.String {
        switch self {
        case .Int:
            return "integer"
        case .Bool:
            return "boolean"
        case .Float:
            return "float"
        case .Double:
            return "double"
        case .String:
            return "string"
        case .Data:
            return "data"
        case .Any:
            return "any"
        case .Date:
            return "date"
        case .Object:
            return "object"
        case .Array:
            return "array"
        }
    }
    
    public var debugDescription: Swift.String {
        return description
    }
    
}
