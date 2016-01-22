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
#import <RealmConvertKit/RealmConvertKit-Swift.h>

#import <Realm/Realm.h>
#import <Realm/RLMRealmConfiguration_Private.h>

NSString * const kRLMTestDirectoryName = @"io.realm.test-output";

@interface ConvertKitObjCTests : XCTestCase

- (NSString *)tempOutputPath;

@end

@implementation ConvertKitObjCTests

- (void)setUp {
    [super setUp];
    
    NSString *filePath = self.tempOutputPath;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    [fileManager removeItemAtPath:filePath error:nil];
    [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    XCTAssertTrue([fileManager fileExistsAtPath:filePath]);
}

- (void)tearDown {
    [[NSFileManager defaultManager] removeItemAtPath:self.tempOutputPath error:nil];
    [super tearDown];
}

- (void)testExporter {
    NSError *error = nil;
    
    // Get a reference to our test realm file in the parent class's resource bundle
    NSString *realmFilePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"dogs" ofType:@"realm"];
    XCTAssertNotNil(realmFilePath);
    
    // Test the exporter and ensure it didn't generate any errors
    RLMDataExporter *exporter = [[RLMDataExporter alloc] initWithOutputFolderPath:self.tempOutputPath realmFilePath:realmFilePath];
    [exporter exportWithType:@"csv" error:&error];
    XCTAssertNil(error);
    
    // Get the contents of the output folder to verify the exporter's results
    NSArray *outputContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.tempOutputPath error:&error];
    XCTAssertNil(error);
    
    // Check that there are indeed files in the output folder, and they match the realm file's schema
    NSInteger numberOfGeneratedFiles = outputContents.count;
    XCTAssertGreaterThan(numberOfGeneratedFiles, 0);
    
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.path = realmFilePath;
    configuration.readOnly = YES;
    configuration.dynamic = YES;
    
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(realm);
    
    RLMSchema *schema = realm.schema;
    XCTAssertEqual(schema.objectSchema.count, numberOfGeneratedFiles);
}

- (NSString *)tempOutputPath
{
    NSString *filePath = NSTemporaryDirectory();
    filePath = [filePath stringByAppendingPathComponent:kRLMTestDirectoryName];
    return filePath;
}

@end
