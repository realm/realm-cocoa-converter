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
 An abstract class manages the common logic for 
 setting up objects that can export the contents of 
 Realm files to another format.
*/
open class DataExporter: NSObject {
    
    open let realm: RLMRealm
    
    /**
     Create a new instance of the exporter object
     
     - parameter realmFilePath: An absolute path to the Realm file to be exported
     */
    @objc(initWithRealmFileAtPath:error:)
    public convenience init(realmFilePath: String) throws {
        let configuration = RLMRealmConfiguration.default()
        configuration.fileURL = URL(fileURLWithPath: realmFilePath)
        configuration.dynamic = true

        let realm = try RLMRealm(configuration: configuration)

        self.init(realm: realm)
    }

    /**
     Create a new instance of the exporter object

     - parameter realm: An instance of Realm to be exported
     */
    @objc(initWithRealm:)
    public init(realm: RLMRealm) {
        if realm.configuration.dynamic {
            self.realm = realm
        } else {
            let configuration = realm.configuration
            configuration.dynamic = true

            self.realm = try! RLMRealm(configuration: configuration)
        }
    }

    /**
     Exports all of the contents of the provided Realm file to
     the designated output folder.
     
     - warning: This method must be overridden by a subclass, that does *not* call `super`
     */
    @objc(exportToFolderAtPath:withError:)
    open func export(toFolderAtPath outputFolderPath: String) throws {
        fatalError("Cannot call export() from DataExporter base class")
    }

}
