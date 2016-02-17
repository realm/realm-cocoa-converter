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

#import <XCTest/XCTest.h>

#import <RealmConverter/RealmConverter-Swift.h>

#import <Realm/Realm.h>
#import <Realm/RLMRealmConfiguration_Private.h>

NSString * const kRLMTestInputDirectoryName  = @"io.realm.test-input";
NSString * const kRLMTestOutputDirectoryName = @"io.realm.test-output";

NSString * const kRLMTestRealmFileName = @"dogs.realm";

@interface RLMRealmConverter_Exporter : XCTestCase

@property (nonatomic, readonly) NSString *outputTempFolderPath;
@property (nonatomic, readonly) NSString *inputTempFolderPath;

@end

@implementation RLMRealmConverter_Exporter

- (void)setUp {
    [super setUp];
    
    NSError *error = nil;
    
    //Delete the directories if they were already present
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *filePath in @[self.outputTempFolderPath, self.inputTempFolderPath]) {
        if ([fileManager fileExistsAtPath:filePath]) {
            [fileManager removeItemAtPath:filePath error:&error];
            XCTAssertNil(error);
        }
    }
    
    //Create both 'input' and 'output' folders in the tmp directory
    for (NSString *filePath in @[self.outputTempFolderPath, self.inputTempFolderPath]) {
        [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:&error];
        XCTAssertNil(error);
        XCTAssertTrue([fileManager fileExistsAtPath:filePath]);
    }
    
    //Copy our test Realm file to the input folder
    NSString *realmFileBundlePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"dogs" ofType:@"realm"];
    XCTAssertNotNil(realmFileBundlePath);
    NSString *destinationPath = [self.inputTempFolderPath stringByAppendingPathComponent:realmFileBundlePath.lastPathComponent];
    [fileManager copyItemAtPath:realmFileBundlePath toPath:destinationPath error:&error];
    XCTAssertNil(error);
}

- (void)testExporter {
    NSError *error = nil;
    
    // Get a reference to our test realm file in the parent class's resource bundle
    NSString *realmFilePath = [self.inputTempFolderPath stringByAppendingPathComponent:kRLMTestRealmFileName];
    XCTAssertNotNil(realmFilePath);
    
    // Test the exporter and ensure it didn't generate any errors
    RLMCSVDataExporter *exporter = [[RLMCSVDataExporter alloc] initWithRealmFileAtPath:realmFilePath];
    [exporter exportToFolderAtPath:self.outputTempFolderPath withError:&error];
    XCTAssertNil(error);
    
    // Get the contents of the output folder to verify the exporter's results
    NSArray *outputContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.outputTempFolderPath error:&error];
    XCTAssertNil(error);
    
    // Check that there are indeed files in the output folder, and they match the realm file's schema
    NSInteger numberOfGeneratedFiles = outputContents.count;
    XCTAssertGreaterThan(numberOfGeneratedFiles, 0);
    
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.path = realmFilePath;
    configuration.dynamic = YES;
    
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(realm);
    
    RLMSchema *schema = realm.schema;
    XCTAssertEqual(schema.objectSchema.count, numberOfGeneratedFiles);
}

- (NSString *)outputTempFolderPath
{
    static NSString *_outputTempFolderPath;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *filePath = NSTemporaryDirectory();
        filePath = [filePath stringByAppendingPathComponent:@"io.realm.realm-converter.import.output"];
        _outputTempFolderPath = filePath;
    });
    
    return _outputTempFolderPath;
}

- (NSString *)inputTempFolderPath
{
    static NSString *_inputTempFolderPath;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *filePath = NSTemporaryDirectory();
        filePath = [filePath stringByAppendingPathComponent:@"io.realm.realm-converter.import.input"];
        _inputTempFolderPath = filePath;
    });
    
    return _inputTempFolderPath;
}

@end
