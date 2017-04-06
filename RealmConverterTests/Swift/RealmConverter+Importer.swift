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
import Realm.Dynamic
import RealmConverter
import PathKit

@testable import RealmConverter

class RealmConverter_Importer: XCTestCase {
    
    let outputTestFolderName = "io.realm.test-output"
    let inputTestFolderName = "io.realm.test-input"
    
    var outputTestFolderPath: String {
        var path = Path(NSTemporaryDirectory())
        path = path + Path(outputTestFolderName)
        return String(describing: path)
    }
    
    var inputTestFolderPath: String {
        var path = Path(NSTemporaryDirectory())
        path = path + Path(inputTestFolderName)
        return String(describing: path)
    }
    
    let testRealmFileName = "businesses.realm"
    let csvAssetNames = ["businesses"]

    var bundle: Bundle {
        return Bundle(for: type(of: self))
    }
    
    override func setUp() {
        super.setUp()
        
        // Create the input and output folders
        for path in [self.inputTestFolderPath, self.outputTestFolderPath] {
            if FileManager.default.fileExists(atPath: path) {
                try! FileManager.default.removeItem(atPath: path)
            }
        }
        
        // Create the input and output folders
        for path in [self.inputTestFolderPath, self.outputTestFolderPath] {
            try! FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        
        // Copy our CSV test data to the input folder
        for fileName in self.csvAssetNames {
            let filePath = bundle.path(forResource: fileName, ofType: "csv")
            let destinationPath = Path(self.inputTestFolderPath) + Path(filePath!).lastComponent
            
            if FileManager.default.fileExists(atPath: String(describing: destinationPath)) == false {
                try! FileManager.default.copyItem(atPath: filePath!, toPath: String(describing: destinationPath))
            }
        }
    }
    
    func testCSVImport() {
        var filePaths = [String]()
        
        let folderContents = try! FileManager.default.contentsOfDirectory(atPath: self.inputTestFolderPath)
        for file in folderContents {
            let filePath = Path(self.inputTestFolderPath) + Path(file)
            filePaths.append(String(describing: filePath))
        }
        
        let generator =  ImportSchemaGenerator(files: filePaths)
        let schema = try! generator.generate()
        
        let destinationRealmPath = Path(self.outputTestFolderPath)
        let dataImporter = CSVDataImporter(files: filePaths)
        try! dataImporter.importToPath(String(describing: destinationRealmPath), schema: schema)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: String(describing: destinationRealmPath)))
    }

    func testJSONImport() {
        let filePaths = [bundle.path(forResource: "realm", ofType: "json")!]

        let generator =  ImportSchemaGenerator(files: filePaths)
        let schema = try! generator.generate()

        let destinationRealmPath = Path(self.outputTestFolderPath)
        let dataImporter = JSONDataImporter(files: filePaths)
        try! dataImporter.importToPath(String(describing: destinationRealmPath), schema: schema)

        XCTAssertTrue(FileManager.default.fileExists(atPath: String(describing: destinationRealmPath)))
    }

    func testThatPropertyTypesAreDetectedProperlyWhenImportingFromCSV() {
        let csvSchema = try! generateSchemaForFileAtPath(bundle.path(forResource: "import-test", ofType: "csv")!)

        // integerValue,boolValue,floatValue,doubleValue,stringValue,dateValue,arrayReference,mixedValue
        let expectedTypes: [RLMPropertyType] = [.int, .bool, .double, .double, .string, .string, .string, .string]

        for (index, type) in expectedTypes.enumerated() {
            XCTAssertEqual(csvSchema.schemas[0].properties[index].type, type)
        }

        let importer = CSVDataImporter(file: bundle.path(forResource: "import-test", ofType: "csv")!)
        let realm = try! importer.importToPath(outputTestFolderPath, schema: csvSchema)

        validatePropertyTypes(in: realm, className: "import-test", expectedTypes: expectedTypes)
    }

    // FIXME: XLSX import doesn't seem to work at all :(
    func DISABLED_testThatPropertyTypesAreDetectedProperlyWhenImportingFromXLSX() {
        let xlsxSchema = try! generateSchemaForFileAtPath(bundle.path(forResource: "restaurant", ofType: "xlsx")!)
        XCTAssertTrue(xlsxSchema.schemas[0].properties[0].type == .int)
    }

    func testThatPropertyTypesAreDetectedProperlyWhenImportingFromJSON() {
        let jsonSchema = try! generateSchemaForFileAtPath(bundle.path(forResource: "realm", ofType: "json")!)
        XCTAssertTrue(jsonSchema.schemas[0].properties[0].type == .int)
        XCTAssertTrue(jsonSchema.schemas[0].properties[1].type == .string)
    }

    func generateSchemaForFileAtPath(_ path: String) throws -> ImportSchema {
        let generator = ImportSchemaGenerator(files: [path])
        return try generator.generate()
    }

    func validatePropertyTypes(in realm: RLMRealm, className: String, expectedTypes: [RLMPropertyType]) {
        guard let objectSchema = realm.schema.objectSchema.filter({ $0.className == className }).first else {
            return XCTFail("Specified class is not found")
        }

        XCTAssertEqual(objectSchema.properties.count, expectedTypes.count)

        for i in 0..<expectedTypes.count {
            XCTAssertEqual(objectSchema.properties[i].type, expectedTypes[i])
        }
    }

}
