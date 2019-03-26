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
// Unless required by applicable law or agreed to in writing, sof   tware
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import Foundation

@objc(RLMImportSchema)
open class ImportSchema: NSObject {
    @objc var schemas: [ImportObjectSchema] = []
    
    @objc init(schemas: [ImportObjectSchema]) {
        super.init()
        self.schemas = schemas
    }
    
    @objc func toJSON() -> [String: Any] {
        var s = [String: Any]()
        for schema in schemas {
            s[schema.objectClassName] = schema.toJSON()
        }
        return s
    }
}

extension ImportSchema  {
    
    override open var description: String {
        let data = try! JSONSerialization.data(withJSONObject: toJSON() as NSDictionary, options: .prettyPrinted)
        return String(data: data, encoding: .utf8)!
    }
    
    override open var debugDescription: String {
        return description
    }
}
