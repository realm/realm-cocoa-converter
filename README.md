# Realm ConvertKit

Realm ConvertKit is an open source software framework with the goal of making it
easy for developers to bring data from a variety of different container formats
into Realm, and back out again. It has been built in Swift, but can also
be easily utilized in Objective-C projects.

It is still in heavy development, and new formats will be added to it over time.

## Features

### Importer
* Imports from both CSV and XLSX.
* Provides an interface to analyze and intelligently generate a Realm schema from
a given data set.

### Exporter
* Exports a Realm file to CSV.

## Examples

Using Swift's Objective-C bridging, it's possible to use Realm ConvertKit in Objective-C
as well; and all classes on the Objective-C side are pre-fixed with `RLM`.

## Exporting a Realm file to CSV
```
let realmFilePath = '' // Absolute file path to my Realm file
let outputFolderPath = '' // Absolute path to the folder which will hold the CSV files

let csvDataExporter = JSONDataExporter(realmFilePath: realmFilePath, outputFolderPath: outputFolderPath)
try! csvDataExporter.export()
```

# License

Realm ConvertKit is licensed under the Apache license. See the LICENSE file for details.
