//
//  RealmConverter+Importer.m
//  RealmConverter
//
//  Created by Tim Oliver on 17/02/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <RealmConverter/RealmConverter-Swift.h>

#import <Realm/Realm.h>
#import <Realm/RLMRealmConfiguration_Private.h>

@interface RLMRealmConverter_Importer : XCTestCase

@property (nonatomic, readonly) NSString *outputTempFolderPath;
@property (nonatomic, readonly) NSString *inputTempFolderPath;

@end

@implementation RLMRealmConverter_Importer

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
    NSString *realmFileBundlePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"users" ofType:@"xlsx"];
    XCTAssertNotNil(realmFileBundlePath);
    NSString *destinationPath = [self.inputTempFolderPath stringByAppendingPathComponent:realmFileBundlePath.lastPathComponent];
    [fileManager copyItemAtPath:realmFileBundlePath toPath:destinationPath error:&error];
    XCTAssertNil(error);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testXLSXImport {
    NSString *filePath = [self.inputTempFolderPath stringByAppendingPathComponent:@"users.xlsx"];
    RLMImportSchemaGenerator *schemaGenerator = [[RLMImportSchemaGenerator alloc] initWithFile:filePath encoding:EncodingUTF8];
    RLMImportSchema *schema = [schemaGenerator generatedSchemaWithError:nil];
    
    NSString *outputPath = self.outputTempFolderPath;
    RLMXLSXDataImporter *dataImporter = [[RLMXLSXDataImporter alloc] initWithFile:filePath encoding:EncodingUTF8];
    [dataImporter importToPath:outputPath withSchema:schema error:nil];
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
