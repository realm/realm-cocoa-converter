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

/**
 Provided a Realm file and an output destination folder,
 `JSONDataExporter` can export the contents of a Realm file
 as a JSON file.

 A single JSON file is created for all tables in the Realm file.

 - warning: Presently, relationships between Realm objects are
 not captured in the JSON files.
 */
@objc(RLMJSONDataImporter)
open class JSONDataImporter: DataImporter {

    open override func importToPath(_ path: String, schema: ImportSchema) throws -> RLMRealm {
        let realm = try createNewRealmFile(path, schema: schema)

        // We only use a single JSON file to import/export Realms.
        let jsonObject = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: files[0])))

        guard let jsonDictionary = jsonObject as? NSDictionary else {
            throw NSError(domain: "io.realm.converter.error", code: 0, userInfo: nil)
        }

        realm.beginWriteTransaction()
        for modelName in jsonDictionary.allKeys as! [String] {
            let jsonModelObjects = jsonDictionary[modelName]! as! [NSDictionary]
            for jsonModelObject in jsonModelObjects {
                realm.createObject(modelName, withValue: jsonModelObject)
            }
        }
        try realm.commitWriteTransaction()
        return realm
    }
}
