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
#if canImport(TGSpreadsheetWriter)
import TGSpreadsheetWriter
#endif
import Realm

@objc
public enum ImportSchemaFormat: Int {
    case csv
    case json
    case xlsx
}

extension String {
    fileprivate var boolValue: Bool? {
        let lower = lowercased()
        if ["true", "yes"].contains(lower) {
            return true
        } else if ["false", "no"].contains(lower) {
            return false
        }
        return nil
    }
}

/**
 `ImportSchemaGenerator` will analyze the contents of files provided
 to it, and intelligently generate a schema definition object
 with which the structure of a Realm file can be created.
 
 This is then used to map the raw data to the appropriate properties
 when performing the import to Realm.
 */
@objc(RLMImportSchemaGenerator)
open class ImportSchemaGenerator: NSObject {
    @objc let files: [String]
    @objc let encoding: Encoding
    @objc let format: ImportSchemaFormat
    
    /**
     Creates a new instance of `ImportSchemaGenerator`, specifying a single
     file with which to import
     
     - parameter file: The absolute file path to the file that will be used to create the schema.
     - parameter encoding: The text encoding used by the file.
     */
    @objc(initWithFile:encoding:)
    public convenience init(file: String, encoding: Encoding = .utf8) {
        self.init(files: [file], encoding: encoding)
    }
    
    /**
     Creates a new instance of `ImportSchemaGenerator`, specifying a list
     of files to analyze.
     
     - parameter files: An array of absolute file paths to each file that will be used for the schema.
     - parameter encoding: The text encoding used by the file.
     */
    @objc(initWithFiles:encoding:)
    public init(files: [String], encoding: Encoding = .utf8) {
        self.files = files
        self.encoding = encoding
        self.format = ImportSchemaGenerator.importSchemaFormat(files.first!)
    }
    
    /**
    Processes the contents of each file provided and returns a single `ImportSchema` object
    representing all of those files.
    */
    @objc(generatedSchemaWithError:)
    open func generate() throws -> ImportSchema {
        switch format {
        case .csv: return try! generateForCSV()
        case .xlsx:
            #if os(OSX)
            return try! generateForXLSX()
            #else
            fatalError("XLSX is not supported on iOS")
            #endif
        case .json: return try! generateForJSON()
        }
    }

    fileprivate func generateForJSON() throws -> ImportSchema {
        // We only use a single JSON file to import/export Realms.
        let jsonObject = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: files[0])))

        guard let jsonDictionary = jsonObject as? NSDictionary else {
            throw NSError(domain: "io.realm.converter.error", code: 0, userInfo: nil)
        }

        let schemas = (jsonDictionary.allKeys as! [String]).map { modelName -> ImportObjectSchema in
            let schema = ImportObjectSchema(objectClassName: modelName)
            let jsonModelObjects = jsonDictionary[modelName]! as! [NSDictionary]
            let firstJSONModelObject = jsonModelObjects.first!
            schema.properties = (firstJSONModelObject.allKeys as! [String]).enumerated().map { (index, propertyName) in
                var property = ImportObjectSchema.Property(column: UInt(index), originalName: propertyName, name: propertyName)
                let value = firstJSONModelObject[propertyName]!
                switch value {
                case _ as Int: property.type = .int
                case _ as Bool: property.type = .bool
                case _ as Double: property.type = .double
                case _ as String: property.type = .string
                default: property.type = .string
                }
                return property
            }
            return schema
        }
        return ImportSchema(schemas: schemas)
    }

    fileprivate func generateForCSV() throws -> ImportSchema {
        let propertyTypeFallbackOrder: [RLMPropertyType] = [.bool, .int, .double, .string]
        let propertyTypeFallbacksToType = { (type: RLMPropertyType?, fallbackType: RLMPropertyType) -> Bool in
            guard let type = type else {
                return true
            }

            return propertyTypeFallbackOrder.firstIndex(of: type)! <= propertyTypeFallbackOrder.firstIndex(of: fallbackType)!
        }

        let schemas = files.map { (file) -> ImportObjectSchema in
            let inputString = try! NSString(contentsOfFile: file, encoding: encoding.rawValue) as String
            let csv = CSwiftV(with: inputString)
            
            let schema = ImportObjectSchema(objectClassName: Path(file).lastComponentWithoutExtension)
            
            schema.properties = csv.headers.enumerated().map { index, field in
                var property = ImportObjectSchema.Property(column: UInt(index), originalName: field, name: field.camelcaseString)

                property.type = csv.rows.map({ $0[index] }).reduce(nil as RLMPropertyType?) { type, value in
                    if value.boolValue != nil && propertyTypeFallbacksToType(type, .bool) {
                        return .bool
                    } else if Int(value) != nil && propertyTypeFallbacksToType(type, .int) {
                        return .int
                    } else if Double(value) != nil && propertyTypeFallbacksToType(type, .double) {
                        return .double
                    }
                    return .string
                } ?? .string

                return property
            }

            return schema
        }

        return ImportSchema(schemas: schemas)
    }
    
    #if os(OSX)
    fileprivate func generateForXLSX() throws -> ImportSchema {
        let workbook = TGSpreadsheetWriter.readWorkbook(URL(fileURLWithPath: "\(Path(files[0]).absolute())")) as! [String: [[String]]]
        let schemas = workbook.keys.enumerated().map { (index, key) -> ImportObjectSchema in
            let schema = ImportObjectSchema(objectClassName: key.capitalized)
            
            if let sheet = workbook[key] {
                if let headers = sheet.first {
                    schema.properties = headers.enumerated().map({ (index, field) -> ImportObjectSchema.Property in
                        return ImportObjectSchema.Property(column: UInt(index), originalName: field, name: field.camelcaseString)
                    })
                }
                
                let rows = sheet.dropFirst()
                rows.forEach { (row) -> () in
                    row.enumerated().forEach { (index, field) -> () in
                        var property = schema.properties[index]
                        
                        if field.isEmpty {
                            //property.optional = true
                            return
                        }
                        guard property.type == .string else {
                            return
                        }
                        
                        let numberFormatter = NumberFormatter()
                        if let number = numberFormatter.number(from: field) {
                            let numberType = CFNumberGetType(number)
                            switch (numberType) {
                            case
                            .sInt8Type,
                            .sInt16Type,
                            .sInt32Type,
                            .sInt64Type,
                            .charType,
                            .shortType,
                            .intType,
                            .longType,
                            .longLongType,
                            .cfIndexType,
                            .nsIntegerType:
                                if (property.type != .double) {
                                    property.type = .int;
                                }
                            case
                            .float32Type,
                            .float64Type,
                            .floatType,
                            .doubleType,
                            .cgFloatType:
                                property.type = .double;
                            @unknown default:
                                fatalError()
                            }
                        } else {
                            property.type = .string
                        }
                    }
                }
            }
            
            return schema
        }
        
        return ImportSchema(schemas: schemas)
    }
    #endif
    
    fileprivate class func importSchemaFormat(_ file: String) -> ImportSchemaFormat {
        switch Path(file).`extension`!.lowercased() {
        case "xlsx": return .xlsx
        case "json": return .json
        default: return .csv
        }
    }
}
