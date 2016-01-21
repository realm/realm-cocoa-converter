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
import PathKit
import CSwiftV
import SpreadsheetWriter
import Realm
import RealmSwift

@objc
public enum Encoding: UInt {
    case UTF8
}

extension Encoding : RawRepresentable {

    public init?(rawValue: UInt) {
        switch rawValue {
        case NSUTF8StringEncoding:
            self = UTF8
        default:
            self = UTF8
        }
    }

    public var rawValue: UInt {
        switch self {
        case UTF8:
            return NSUTF8StringEncoding
        }
    }

}

@objc(RLMDataImporter)
public class DataImporter : NSObject {
    let files: [String]
    let output: String
    let encoding: Encoding

    convenience public init(file: String, output: String, encoding: Encoding = .UTF8) {
        self.init(files: [file], output: output, encoding: encoding)
    }

    @objc(initWithFiles:output:encoding:)
    public init(files: [String], output: String, encoding: Encoding = .UTF8) {
        self.files = files
        self.output = output
        self.encoding = encoding
    }

    @objc(importWithSchema:type:error:)
    public func `import`(schema: JSONSchema, type: String = "csv") throws -> RLMRealm {
        for schema in schema.schemas {
            let superclassName = "RLMObject"

            let className = schema.objectClassName

            if let cls = objc_getClass(className) as? AnyClass {
                objc_disposeClassPair(cls)
            }
            let cls = objc_allocateClassPair(NSClassFromString(superclassName), className, 0) as! RLMObject.Type

            print(className)
            
            schema.properties.reverse().forEach { (property) -> () in
                let type: objc_property_attribute_t
                let size: Int
                let alignment: UInt8
                let encode: String
                
                switch property.type {
                case .Int:
                    type = objc_property_attribute_t(name: "T".cStringUsingEncoding(NSUTF8StringEncoding), value: "i".cStringUsingEncoding(NSUTF8StringEncoding))
                    size = sizeof(Int64)
                    alignment = UInt8(log2(Double(size)))
                    encode = "q"
                case .Double:
                    type = objc_property_attribute_t(name: "T".cStringUsingEncoding(NSUTF8StringEncoding), value: "d".cStringUsingEncoding(NSUTF8StringEncoding))
                    size = sizeof(Double)
                    alignment = UInt8(log2(Double(size)))
                    encode = "d"
                default:
                    type = objc_property_attribute_t(name: "T".cStringUsingEncoding(NSUTF8StringEncoding), value: "@\"NSString\"".cStringUsingEncoding(NSUTF8StringEncoding))
                    size = sizeof(NSObject)
                    alignment = UInt8(log2(Double(size)))
                    encode = "@"
                }

                class_addIvar(cls, property.originalName, size, alignment, encode)

                let ivar = objc_property_attribute_t(name: "V".cStringUsingEncoding(NSUTF8StringEncoding), value: property.name.cStringUsingEncoding(NSUTF8StringEncoding)!)
                let attrs = [type, ivar]
                class_addProperty(cls, property.originalName, attrs, 2)

                let imp = imp_implementationWithBlock(unsafeBitCast({ () -> Bool in
                    return true
                    } as @convention(block) () -> (Bool), AnyObject.self))
                class_addMethod(cls, "respondsToSelector:", imp, "b@::")
            }

            objc_registerClassPair(cls);

            let imp = imp_implementationWithBlock(unsafeBitCast({ () -> NSArray in
                return schema.properties.filter { !$0.optional }.map { $0.originalName }
                } as @convention(block) () -> (NSArray), AnyObject.self))
            class_addMethod(objc_getMetaClass(className) as! AnyClass, "requiredProperties", imp, "@16@0:8")
        }

        let configuration = RLMRealmConfiguration()
        configuration.path = (output as NSString).stringByAppendingPathComponent("default.realm")
        let realm = try RLMRealm(configuration: configuration)

        switch type {
        case "csv":
            for (index, file) in files.enumerate() {
                let schema = schema.schemas[index]

                let inputString = try! NSString(contentsOfFile: file, encoding: encoding.rawValue) as String
                let csv = CSwiftV(String: inputString)

                var generator = csv.rows.generate()
                transactionLoop: while true {
                    realm.beginWriteTransaction()
                    for _ in 0..<10000 {
                        let cls = NSClassFromString(schema.objectClassName) as! RLMObject.Type
                        let object = cls.init()

                        guard let row = generator.next() else {
                            break transactionLoop
                        }
                        row.enumerate().forEach { (index, field) -> () in
                            let property = schema.properties[index]

                            switch property.type {
                            case .Int:
                                if let number = Int64(field) {
                                    object.setValue(NSNumber(longLong: number), forKey: property.originalName)
                                }
                            case .Double:
                                if let number = Double(field) {
                                    object.setValue(NSNumber(double: number), forKey: property.originalName)
                                }
                            default:
                                object.setValue(field, forKey: property.originalName)
                            }
                        }
                        
                        realm.addObject(object)
                    }
                    try realm.commitWriteTransaction()
                }
                try realm.commitWriteTransaction()
            }
            
            //return try Realm(configuration: Realm.Configuration(path: configuration.path));
            return realm
            
        case "xlsx":
            let workbook = SpreadsheetWriter.ReadWorkbook(NSURL(fileURLWithPath: "\(Path(files[0]).absolute())")) as! [String: [[String]]]
            for (index, key) in workbook.keys.enumerate() {
                let schema = schema.schemas[index]

                if let sheet = workbook[key] {
                    let rows = sheet.dropFirst()
                    for row in rows {
                        let cls = NSClassFromString(schema.objectClassName) as! RLMObject.Type
                        let object = cls.init()
                        
                        row.enumerate().forEach { (index, field) -> () in
                            let property = schema.properties[index]

                            switch property.type {
                            case .Int:
                                if let number = Int64(field) {
                                    object.setValue(NSNumber(longLong: number), forKey: property.name)
                                }
                            case .Double:
                                if let number = Double(field) {
                                    object.setValue(NSNumber(double: number), forKey: property.name)
                                }
                            default:
                                object.setValue(field, forKey: property.name)
                            }
                        }

                        try realm.transactionWithBlock { () -> Void in
                            realm.addObject(object)
                        }
                    }
                }
            }

            return realm
            
        default:
            fatalError()
        }
    }
}
