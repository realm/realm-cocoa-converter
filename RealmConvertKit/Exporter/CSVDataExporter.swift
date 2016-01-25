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
public class CSVDataExporter : NSObject {
    
    public var outputFolderPath = ""
    public var realmFilePath    = ""
    public var delimiter        = ","
    public var escapeQuotes     = "\""
    
    /**
     Create a new instance of the exporter object
     
     - parameter realmFilePath: An absolute path to the Realm file to be exported
     - parameter outputFolderpath: An absolute path to a folder where the CSV files will be created
     */
    @objc(initWithRealmFileAtPath:outputToFolderAtPath:)
    public init (realmFilePath: String, outputFolderPath: String) {
        self.outputFolderPath = outputFolderPath
        self.realmFilePath = realmFilePath
    }
    
    /**
     Exports all of the contents of the provided Realm file to 
     the designated output folder, in CSV
     */
    @objc(exportWithError:)
    public func export() throws {
        
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