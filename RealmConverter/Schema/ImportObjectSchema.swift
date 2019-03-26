////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import Foundation
import Realm

@objc(RLMImportObjectSchema)
open class ImportObjectSchema: NSObject {
    @objc open var objectClassName: String
    var properties: [ImportObjectSchema.Property] = []
    
    @objc init(objectClassName: String) {
        self.objectClassName = objectClassName
        super.init()
    }
    
    @objc func toJSON() -> [String: Any] {
        let fields = properties.map { (property) -> [String: Any] in
            return property.toJSON()
        }
        return ["fields": fields, "primaryKey": NSNull()]
    }
    
    struct Property {
        let column: UInt
        let originalName: String
        let name: String
        var type: RLMPropertyType = .string
        var indexed = false
        var optional = false
        var array = false
        
        init(column: UInt, originalName: String, name: String) {
            self.column = column
            self.originalName = originalName
            self.name = name
        }
        
        func toJSON() -> [String: Any] {
            return [
                "column": column,
                "originalName": originalName,
                "name": name,
                "type": "\(type)",
                "indexed": indexed,
                "optional": optional,
                "array": array,
            ]
        }
    }
}

extension ImportObjectSchema {
    
    override open var description: String {
        let data = try! JSONSerialization.data(withJSONObject: toJSON(), options: .prettyPrinted)
        return String(data: data, encoding: .utf8)!
    }
    
    override open var debugDescription: String {
        return description
    }
    
}

// MARK: - String Extension for Realm PropertyType -
extension RLMPropertyType: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: Swift.String {
        switch self {
        case .int:
            return "integer"
        case .bool:
            return "boolean"
        case .float:
            return "float"
        case .double:
            return "double"
        case .string:
            return "string"
        case .data:
            return "data"
        case .any:
            return "any"
        case .date:
            return "date"
        case .object:
            return "object"
        case .linkingObjects:
            return "linkingobjects"
        }
    }
    
    public var debugDescription: Swift.String {
        return description
    }
}
