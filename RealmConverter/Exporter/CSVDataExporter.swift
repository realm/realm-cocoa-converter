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

/**
 Provided a Realm file and an output destination folder,
 `CSVDataExporter` can export the contents of a Realm file
 to a series of CSV files.
 
 A single CSV file is created for each table in the Realm file,
 with strings being escaped in the default CSV standard.
 
 - warning: Presently, relationships between Realm objects are
 not captured in the CSV files.
*/
@objc(RLMCSVDataExporter)
public class CSVDataExporter: DataExporter {
    
    /**
     The delimiter symbol used to separate each property on each row.
     Defaults to the CSV standard ',' comma.
     */
    public var delimiter        = ","
    
    /**
     When it's necessary to escape a Realm property on a CSV row, this is the escape symbol
     Defaults to the CSV standard '"' double-quotes.
     */
    public var escapeQuotes     = "\""
    
    /**
     Takes the provided Realm file and exports each table to a CSV file in the provided
     output folder.
     */
    public override func export() throws {
        
        let realmConfiguration = RLMRealmConfiguration.defaultConfiguration()
        realmConfiguration.path = self.realmFilePath
        realmConfiguration.dynamic = true
        
        let realm = try RLMRealm(configuration: realmConfiguration)
        let schema = realm.schema
        
        //Write out a .csv file for each object in the Realm
        for objectSchema in schema.objectSchema {
            
            let objectName = objectSchema.className
            let fileName = "\(objectName).csv"
            let filePath = Path(self.outputFolderPath) + Path(fileName)
            
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
                        //If the value is a single child object
                        if value is RLMObject {
                            rowString += self.serializedObject((value as! RLMObject), realm: realm)!
                        }
                        else if value is RLMArray {
                            rowString += self.serializedObjectArray((value as! RLMArray), realm: realm)!
                        }
                        else {
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
    
    private func serializedObject(object: RLMObject, realm: RLMRealm) -> String? {
        let className = object.objectSchema.className
        let allObjects = realm.allObjects(className)
        let index = Int(allObjects.indexOfObject(object))
        if index == NSNotFound {
            return nil
        }
        
        return "<\(className)>{\(index)}"
    }
    
    private func serializedObjectArray(array: RLMArray, realm: RLMRealm) -> String? {
        if array.count == 0 {
            return nil
        }
        
        let className = array.objectClassName
        let allObjects = realm.allObjects(className)
        
        var string = "<\(className)>{"
        
        for var i = 0; i < Int(array.count); i++ {
            let object = array.objectAtIndex(UInt(i))
            let index = allObjects.indexOfObject(object)
            
            if Int(index) != NSNotFound {
                string += "\(index)"
            }
        }
        string = string.substringToIndex(string.endIndex.predecessor()) 
        string += "}"
        
        return string
    }
}