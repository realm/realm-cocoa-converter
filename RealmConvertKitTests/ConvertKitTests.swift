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
import XCTest
import Realm
import RealmSwift
import PathKit

@testable import ConvertKit

class ConvertKitTests: XCTestCase {
    let testRealmFileName = "io.realm.test.realm"
    
    var testRealmFilePath:String {
        let path = Path(NSTemporaryDictory())
        path += Path(self.testRealmFileName)
        return path.path
    }
    
    override func setUp() {
        super.setUp()
        
        
    }
    
    override func tearDown() {
        //Delete any outstanding realm files from previous tests
        NSFileManager.defaultFileManager().removeItemAtPath(self.testRealmFilePath, error: nil)
        
        super.tearDown()
    }
    
    func testCSVImport() {
        let businessesCSVFilePath = NSBundle.mainBundle().pathForResource("businesses", ofType: "csv")
        XCTAssetNotNil(businessesCSVFilePath)
        
        let generator = JSONTableSchemaGenerator(file: businessesCSVFilePath)
        let schema = try generator.generate("csv")
        
        let dataImporter = DataImporter(businessesCSVFilePath, self.testRealmFilePath)
        dataImporter.`import`(schema: schema)
        
        XCTAssertTrue(NSFileManager.defaultFileManager().fileExistsAtPath(self.testRealmFilePath))
    }
    
}
