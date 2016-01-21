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
import Realm.Private
import Realm.Dynamic
import RealmSwift
import PathKit

@objc(RLMDataExporter)
public class DataExporter : NSObject {
    let output: String
    let realmFilePath: String
    let delimiter: String = ","
    let escapeQuotes = "\""
    
    @objc(initWithOutputFolderPath:realmFilePath:)
    public init (outputFolderPath: String, realmFilePath: String) {
        self.output = outputFolderPath
        self.realmFilePath = realmFilePath
    }
    
    @objc(exportWithType:error:)
    public func export(type: String = "csv") throws -> String {
        let realmConfiguration = RLMRealmConfiguration.defaultConfiguration()
        realmConfiguration.path = self.realmFilePath
        realmConfiguration.dynamic = true
        
        let realm = try RLMRealm(configuration: realmConfiguration)
        let schema = realm.schema
        
        //Write out a .csv file for each object in the Realm
        for objectSchema in schema.objectSchema {
            
            let objectName = objectSchema.className
            let fileName = "\(objectName).csv"
            let filePath = Path(self.output) + Path(fileName)
            
            if filePath.exists {
                try filePath.delete()
            }
            
            // Build the initial row of property names and write to disk
            let properties = objectSchema.properties
            var propertyNamesRow: String = ""
            for property in properties {
                propertyNamesRow += "\(property.name)"
                propertyNamesRow += self.delimiter
            }
            propertyNamesRow.removeAtIndex(propertyNamesRow.endIndex.predecessor())
            
            try filePath.write(propertyNamesRow+"\n")
            
            // Write the remaining objects
            let fileHandle = NSFileHandle(forWritingAtPath: String(filePath))
            fileHandle?.seekToEndOfFile()
            
            let objects = realm.allObjects(objectSchema.className)
            
            // Loop through each object in the table
            for index in 0..<objects.count {
                var rowString: String = ""
                let object = objects.objectAtIndex(index) as RLMObject
                
                // Loop through each property in the object
                for property in properties {
                    let value = object[property.name]
                    if value != nil {
                        if !(value is RLMObject) {
                            rowString += self.sanitizedValue(value!.description!)
                        }
                    }
                    
                    rowString += self.delimiter
                }
                //remove the final delimiter
                rowString.removeAtIndex(rowString.endIndex.predecessor())
                
                //add the line break
                rowString += "\n"
                
                fileHandle?.writeData(rowString.dataUsingEncoding(NSUTF8StringEncoding)!)
            }
            fileHandle?.closeFile()
        }
        
        return self.output
    }
    
    private func sanitizedValue(value: String) -> String {
        var needsEscapeQuotes = false
        var sanitizedValue = value
        
        //Value already contains escape quotes, replace with 2 sets of quotes
        if sanitizedValue.rangeOfString(self.escapeQuotes) != nil {
            let replaceString = (self.escapeQuotes+self.escapeQuotes)
            sanitizedValue = sanitizedValue.stringByReplacingOccurrencesOfString(self.escapeQuotes, withString:replaceString)
            needsEscapeQuotes = true
        }
        
        if value.rangeOfString(" ") != nil || value.rangeOfString(self.delimiter) != nil {
            needsEscapeQuotes = true
        }
        
        if needsEscapeQuotes {
            sanitizedValue = "\(self.escapeQuotes)\(sanitizedValue)\(self.escapeQuotes)"
        }
        
        return sanitizedValue
    }
}