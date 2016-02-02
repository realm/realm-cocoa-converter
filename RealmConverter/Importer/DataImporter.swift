//
//  DataImporter.swift
//  RealmConverter
//
//  Created by Tim Oliver on 25/01/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

@objc (RLMDataImporter)
public class DataImporter: NSObject {
    public let files: [String]
    public let output: String
    public let encoding: Encoding
    
    @objc(initWithFile:output:encoding:)
    convenience public init(file: String, output: String, encoding: Encoding = .UTF8) {
        self.init(files: [file], output: output, encoding: encoding)
    }
    
    @objc(initWithFiles:output:encoding:)
    public init(files: [String], output: String, encoding: Encoding = .UTF8) {
        self.files = files
        self.output = output
        self.encoding = encoding
    }
    
    @objc(createNewRealmFileWithSchema:error:)
    public func createNewRealmFile(schema: ImportSchema) throws -> RLMRealm {
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
        
        return realm
    }
    
    @objc(importWithSchema:error:)
    func `import`(schema: ImportSchema) throws -> RLMRealm {
        fatalError("import() can not be called on the base data importer class")
    }
}