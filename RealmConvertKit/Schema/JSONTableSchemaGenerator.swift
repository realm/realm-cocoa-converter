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
import SpreadsheetWriter


extension String {
    
    var camelcaseString: String {
        guard !isEmpty else {
            return ""
        }
        let delimiters = NSCharacterSet(charactersInString: "_-")
        let pascalcaseString = capitalizedString.componentsSeparatedByCharactersInSet(delimiters).joinWithSeparator("")
        return "\(pascalcaseString.substringToIndex(startIndex.advancedBy(1)).lowercaseString)\(pascalcaseString.substringFromIndex(startIndex.advancedBy(1)))"
    }
    
}

public struct JSONTableSchemaGenerator {
    let files: [String]
    let type: String
    let output: String
    let encoding: Encoding
    
    public init(file: String, type: String = "", output: String, encoding: Encoding = .UTF8) {
        self.init(files: [file], type: type, output: output, encoding: encoding)
    }
    
    public init(files: [String], type: String = "", output: String, encoding: Encoding = .UTF8) {
        self.files = files
        self.type = type
        self.output = output
        self.encoding = encoding
    }
    
    public func generate(type: String = "csv") throws -> JSONSchema {
        switch type {
        case "csv":
            let schemas = files.map { (file) -> JSONObjectSchema in
                let inputString = try! NSString(contentsOfFile: file, encoding: encoding.rawValue) as String
                let csv = CSwiftV(String: inputString)
                
                let schema = JSONObjectSchema(objectClassName: Path(file).lastComponentWithoutExtension)
                
                schema.properties = csv.headers.enumerate().map { (index, field) -> JSONObjectSchema.Property in
                    return JSONObjectSchema.Property(column: UInt(index), originalName: field, name: field.camelcaseString)
                }
                
                csv.rows.forEach { (row) -> () in
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
                            case .SInt8Type: fallthrough
                            case .SInt16Type: fallthrough
                            case .SInt32Type: fallthrough
                            case .SInt64Type: fallthrough
                            case .CharType: fallthrough
                            case .ShortType: fallthrough
                            case .IntType: fallthrough
                            case .LongType: fallthrough
                            case .LongLongType: fallthrough
                            case .CFIndexType: fallthrough
                            case .NSIntegerType:
                                if (property.type != .Double) {
                                    property.type = .Int;
                                }
                                break;
                            case .Float32Type: fallthrough
                            case .Float64Type: fallthrough
                            case .FloatType: fallthrough
                            case .DoubleType: fallthrough
                            case .CGFloatType:
                                property.type = .Double;
                                break;
                            }
                        } else {
                            property.type = .String
                        }
                    }
                }
                
                return schema
            }
            
            return JSONSchema(schemas: schemas)
            
        case "xlsx":
            let workbook = SpreadsheetWriter.ReadWorkbook(NSURL(fileURLWithPath: "\(Path(files[0]).absolute())")) as! [String: [[String]]]
            
            let schemas = workbook.keys.enumerate().map { (index, key) -> JSONObjectSchema in
                let schema = JSONObjectSchema(objectClassName: key.capitalizedString)
                
                if let sheet = workbook[key] {
                    if let headers = sheet.first {
                        schema.properties = headers.enumerate().map({ (index, field) -> JSONObjectSchema.Property in
                            return JSONObjectSchema.Property(column: UInt(index), originalName: field, name: field.camelcaseString)
                        })
                    }
                    
                    let rows = sheet.dropFirst()
                    rows.forEach { (row) -> () in
                        row.enumerate().forEach { (index, field) -> () in
                            var property = schema.properties[index]
                            
                            if field.isEmpty {
                                //                                property.optional = true
                                return
                            }
                            guard property.type == .String else {
                                return
                            }
                            
                            let numberFormatter = NSNumberFormatter()
                            if let number = numberFormatter.numberFromString(field) {
                                let numberType = CFNumberGetType(number)
                                switch (numberType) {
                                case .SInt8Type: fallthrough
                                case .SInt16Type: fallthrough
                                case .SInt32Type: fallthrough
                                case .SInt64Type: fallthrough
                                case .CharType: fallthrough
                                case .ShortType: fallthrough
                                case .IntType: fallthrough
                                case .LongType: fallthrough
                                case .LongLongType: fallthrough
                                case .CFIndexType: fallthrough
                                case .NSIntegerType:
                                    if (property.type != .Double) {
                                        property.type = .Int;
                                    }
                                    break;
                                case .Float32Type: fallthrough
                                case .Float64Type: fallthrough
                                case .FloatType: fallthrough
                                case .DoubleType: fallthrough
                                case .CGFloatType:
                                    property.type = .Double;
                                    break;
                                }
                            } else {
                                property.type = .String
                            }
                        }
                    }
                }
                
                return schema
            }
            
            return JSONSchema(schemas: schemas)
            
        default:
            fatalError()
        }
    }
}