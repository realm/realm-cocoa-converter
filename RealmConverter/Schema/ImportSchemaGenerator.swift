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
import CSwiftV
import PathKit
import TGSpreadsheetWriter
import Realm

@objc
public enum ImportSchemaFormat: Int {
    case CSV
    case JSON
    case XLSX
}

/**
 `ImportSchemaGenerator` will analyze the contents of files provided
 to it, and intelligently generate a schema definition object
 with which the structure of a Realm file can be created.
 
 This is then used to map the raw data to the appropriate properties
 when performing the import to Realm.
 */
@objc(RLMImportSchemaGenerator)
public class ImportSchemaGenerator: NSObject {
    let files: [String]
    let encoding: Encoding
    let format: ImportSchemaFormat
    
    /**
     Creates a new instance of `ImportSchemaGenerator`, specifying a single
     file with which to import
     
     - parameter file: The absolute file path to the file that will be used to create the schema.
     - parameter encoding: The text encoding used by the file.
     */
    @objc(initWithFile:encoding:)
    public convenience init(file: String, encoding: Encoding = .UTF8) {
        self.init(files: [file], encoding: encoding)
    }
    
    /**
     Creates a new instance of `ImportSchemaGenerator`, specifying a list
     of files to analyze.
     
     - parameter files: An array of absolute file paths to each file that will be used for the schema.
     - parameter encoding: The text encoding used by the file.
     */
    @objc(initWithFiles:encoding:)
    public init(files: [String], encoding: Encoding = .UTF8) {
        self.files = files
        self.encoding = encoding
        self.format = ImportSchemaGenerator.importSchemaFormat(files.first!)
    }
    
    /**
    Processes the contents of each file provided and returns a single `ImportSchema` object
    representing all of those files.
    */
    @objc(generatedSchemaWithError:)
    public func generate() throws -> ImportSchema {
        switch format {
        case .CSV: return try! generateForCSV()
        case .XLSX: return try! generateForXLSX()
        case .JSON: return try! generateForJSON()
        }
    }

    private func generateForJSON() throws -> ImportSchema {
        // We only use a single JSON file to import/export Realms.
        let jsonObject = try NSJSONSerialization.JSONObjectWithData(NSData(contentsOfFile: files[0])!, options: [])

        guard let jsonDictionary = jsonObject as? NSDictionary else {
            throw NSError(domain: "io.realm.converter.error", code: 0, userInfo: nil)
        }

        let schemas = (jsonDictionary.allKeys as! [String]).map { modelName -> ImportObjectSchema in
            let schema = ImportObjectSchema(objectClassName: modelName)
            let jsonModelObjects = jsonDictionary[modelName]! as! [NSDictionary]
            let firstJSONModelObject = jsonModelObjects.first!
            schema.properties = (firstJSONModelObject.allKeys as! [String]).enumerate().map { (index, propertyName) in
                var property = ImportObjectSchema.Property(column: UInt(index), originalName: propertyName, name: propertyName)
                let value = firstJSONModelObject[propertyName]!
                switch value {
                case _ as Int: property.type = .Int
                case _ as Bool: property.type = .Bool
                case _ as Double: property.type = .Double
                case _ as String: property.type = .String
                default: property.type = .String
                }
                return property
            }
            return schema
        }
        return ImportSchema(schemas: schemas)
    }

    private func generateForCSV() throws -> ImportSchema {
        let schemas = files.map { (file) -> ImportObjectSchema in
            let inputString = try! NSString(contentsOfFile: file, encoding: encoding.rawValue) as String
            let csv = CSwiftV(string: inputString)
            
            let schema = ImportObjectSchema(objectClassName: Path(file).lastComponentWithoutExtension)
            
            schema.properties = csv.headers.enumerate().map { index, field in
                var property = ImportObjectSchema.Property(column: UInt(index), originalName: field, name: field.camelcaseString)

                property.type = csv.rows.map({ $0[index] }).reduce(nil as RLMPropertyType?) { type, value in
                    let typeRawValue = type?.rawValue ?? 0

                    if Int(value) != nil && typeRawValue <= RLMPropertyType.Int.rawValue {
                        return .Int
                    } else if Double(value) != nil && typeRawValue <= RLMPropertyType.Double.rawValue {
                        return .Double
                    } else {
                        return .String
                    }
                } ?? .String

                return property
            }

            return schema
        }
        
        return ImportSchema(schemas: schemas)
    }
    
    private func generateForXLSX() throws -> ImportSchema {
        let workbook = TGSpreadsheetWriter.readWorkbook(NSURL(fileURLWithPath: "\(Path(files[0]).absolute())")) as! [String: [[String]]]
        let schemas = workbook.keys.enumerate().map { (index, key) -> ImportObjectSchema in
            let schema = ImportObjectSchema(objectClassName: key.capitalizedString)
            
            if let sheet = workbook[key] {
                if let headers = sheet.first {
                    schema.properties = headers.enumerate().map({ (index, field) -> ImportObjectSchema.Property in
                        return ImportObjectSchema.Property(column: UInt(index), originalName: field, name: field.camelcaseString)
                    })
                }
                
                let rows = sheet.dropFirst()
                rows.forEach { (row) -> () in
                    row.enumerate().forEach { (index, field) -> () in
                        var property = schema.properties[index]
                        
                        if field.isEmpty {
                            //property.optional = true
                            return
                        }
                        guard property.type == .String else {
                            return
                        }
                        
                        let numberFormatter = NSNumberFormatter()
                        if let number = numberFormatter.numberFromString(field) {
                            let numberType = CFNumberGetType(number)
                            switch (numberType) {
                            case
                            .SInt8Type,
                            .SInt16Type,
                            .SInt32Type,
                            .SInt64Type,
                            .CharType,
                            .ShortType,
                            .IntType,
                            .LongType,
                            .LongLongType,
                            .CFIndexType,
                            .NSIntegerType:
                                if (property.type != .Double) {
                                    property.type = .Int;
                                }
                            case
                            .Float32Type,
                            .Float64Type,
                            .FloatType,
                            .DoubleType,
                            .CGFloatType:
                                property.type = .Double;
                            }
                        } else {
                            property.type = .String
                        }
                    }
                }
            }
            
            return schema
        }
        
        return ImportSchema(schemas: schemas)
    }
    
    private class func importSchemaFormat(file: String) -> ImportSchemaFormat {
        switch Path(file).`extension`!.lowercaseString {
        case "xlsx": return .XLSX
        case "json": return .JSON
        default: return .CSV
        }
    }
}
