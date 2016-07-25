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

import XCTest
import Realm

@testable import RealmConverter

class CSVExportTests: XCTestCase {
    
    let outputDirectoryPath = NSTemporaryDirectory() + "io.realmconverter.test-output"
    
    override func setUp() {
        super.setUp()
        
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(outputDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            XCTFail("Failed to create output directory: \(error.localizedFailureReason)")
        }
    }
    
    override func tearDown() {
        do {
            try NSFileManager.defaultManager().removeItemAtPath(outputDirectoryPath)
        } catch let error as NSError {
            XCTFail("Failed to remove output directory: \(error.localizedFailureReason)")
        }
        
        super.tearDown()
    }
    
    func testThatCSVDataExorterExportsEmptyRelationships() {
        guard let realmPath = NSBundle(forClass: self.dynamicType).pathForResource("relationships", ofType: "realm") else {
            XCTFail("Realm not found")
            return
        }
        
        do {
            try exportToCSVAndCheckResults(realmPath, outputDirectoryPath: outputDirectoryPath)
        } catch let error as NSError {
            XCTFail("CSV expord failed: \(error.localizedDescription)")
        }
        
    }
    
    func exportToCSVAndCheckResults(realmPath: String, outputDirectoryPath: String) throws {
        let exporter = CSVDataExporter(realmFilePath: realmPath)
        
        try exporter.exportToFolderAtPath(outputDirectoryPath)
        
        let configuration = RLMRealmConfiguration.defaultConfiguration()
        configuration.fileURL = NSURL(fileURLWithPath: realmPath)
        configuration.dynamic = true
        
        let realm = try RLMRealm(configuration: configuration)
        
        let schema = realm.schema
        
        for object in schema.objectSchema {
            XCTAssert(NSFileManager.defaultManager().fileExistsAtPath("\(outputDirectoryPath)/\(object.className).csv"))
        }
    }
    
}
