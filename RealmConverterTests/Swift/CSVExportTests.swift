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
            try FileManager.default.createDirectory(atPath: outputDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            XCTFail("Failed to create output directory: \(String(describing: error.localizedFailureReason))")
        }
    }
    
    override func tearDown() {
        do {
            try FileManager.default.removeItem(atPath: outputDirectoryPath)
        } catch let error as NSError {
            XCTFail("Failed to remove output directory: \(String(describing: error.localizedFailureReason))")
        }
        
        super.tearDown()
    }
    
    func testThatCSVDataExorterExportsEmptyRelationships() {
        guard let realmPath = Bundle(for: type(of: self)).path(forResource: "relationships", ofType: "realm") else {
            XCTFail("Realm not found")
            return
        }
        
        do {
            try exportToCSVAndCheckResults(realmPath, outputDirectoryPath: outputDirectoryPath)
        } catch let error as NSError {
            XCTFail("CSV expord failed: \(error.localizedDescription)")
        }
        
    }
    
    func exportToCSVAndCheckResults(_ realmPath: String, outputDirectoryPath: String) throws {
        let exporter = try CSVDataExporter(realmFilePath: realmPath)
        
        try exporter.exportToFolderAtPath(outputDirectoryPath)
        
        let configuration = RLMRealmConfiguration.default()
        configuration.fileURL = URL(fileURLWithPath: realmPath)
        configuration.dynamic = true
        
        let realm = try RLMRealm(configuration: configuration)
        
        let schema = realm.schema
        
        for object in schema.objectSchema {
            XCTAssert(FileManager.default.fileExists(atPath: "\(outputDirectoryPath)/\(object.className).csv"))
        }
    }
    
}
