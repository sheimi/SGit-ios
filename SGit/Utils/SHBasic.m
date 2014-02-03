//
//  SHBasic.m
//  SGit
//
//  Created by Rizhen Zhang on 1/2/14.
//  Copyright (c) 2014 Rizhen Zhang. All rights reserved.
//

#import "SHBasic.h"
#import <CommonCrypto/CommonDigest.h>

@interface SHBasic ()

@end

@implementation SHBasic

@synthesize property = _property;
@synthesize defaultKeyPair = _defaultKeyPair;
@synthesize keyPairs = _keyPairs;

static NSString *const PROPERTY_FILE = @"property.plist";
static NSString *const PRIVATE_KEY_DIR = @"keys";

SHBasic *basic = nil;

+ (SHBasic *) defaultBasic
{
    if (basic == nil) {
        basic = [[SHBasic alloc] init];
    }
    return basic;
}

- (NSString *)keyDir {
    if (_keyDir == nil) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *appDocsDir = [[fileManager URLsForDirectory:NSDocumentDirectory
                                                 inDomains:NSUserDomainMask] lastObject];
        NSString *appDocsDirPath = appDocsDir.path;
        NSString *keyPath = [appDocsDirPath stringByAppendingPathComponent:PRIVATE_KEY_DIR];
        if (![fileManager fileExistsAtPath:keyPath]) {
            [fileManager createDirectoryAtPath:keyPath
                   withIntermediateDirectories:NO
                                    attributes:nil
                                         error:nil];
        }
        _keyDir = keyPath;
    }
    return _keyDir;
}

- (NSString *)defaultKeyPair
{
    if (_defaultKeyPair == nil) {
        _defaultKeyPair = [self.property objectForKey:@"key.default"];
    }
    return _defaultKeyPair;
}

- (NSMutableDictionary *) keyPairs
{
    if (_keyPairs == nil) {
        _keyPairs = [self.property objectForKey:@"key.keys"];
        if (_keyPairs == nil) {
            _keyPairs = [[NSMutableDictionary alloc] init];
            [self.property setObject:_keyPairs forKey:@"key.keys"];
        }
    }
    return _keyPairs;
}

- (void)setDefaultKeyPair:(NSString *)defaultKeyPair
{
    _defaultKeyPair = defaultKeyPair;
    [self.property setObject:defaultKeyPair forKey:@"key.default"];
    [self saveProperty];
}

- (NSDictionary *) keyPairByKeyName: (NSString *)name
{
    return [self.keyPairs objectForKey:name];
}

- (void) setKeyPair: (NSDictionary *)keyPair
          byKeyName:(NSString *)name
{
    [self.keyPairs setObject:keyPair forKey:name];
    [self saveProperty];
}

- (NSString *) privateKeyPath:(NSString *)keyName
{
    return [self.keyDir stringByAppendingPathComponent:keyName];
}


- (NSString *) publicKeyPath:(NSString *)name
{
    return [[self privateKeyPath:name] stringByAppendingPathExtension:@"pub"];
}

- (NSString *) defaultPrivateKeyPath
{
    NSString *name = [self.property objectForKey:@"key.default"];
    if (name == nil || [name isEqualToString:@""])
        return nil;
    return [self privateKeyPath:name];
}

- (NSString *) defaultPublicKeyPath
{
    NSString *private = [self defaultPrivateKeyPath];
    if (private == nil)
        return nil;
    return [private stringByAppendingPathExtension:@"pub"];
}

- (void) removeKeyPair:(NSString *)name
{
    NSString *privateKeyPath = [self privateKeyPath:name];
    NSString *publicKeyPath = [self publicKeyPath:name];
    [[NSFileManager defaultManager] removeItemAtPath:privateKeyPath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:publicKeyPath error:nil];
    [[self.property objectForKey:@"key.keys"] removeObjectForKey:name];
    [self saveProperty];
}

- (NSMutableDictionary *)property
{
    if (_property == nil) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *appDocsDir = [[fileManager URLsForDirectory:NSDocumentDirectory
                                                 inDomains:NSUserDomainMask] lastObject];
        NSURL *propertyURL = [NSURL URLWithString:PROPERTY_FILE
                                    relativeToURL:appDocsDir];
        if ([[NSFileManager defaultManager] fileExistsAtPath:propertyURL.path]) {
            _property = [NSMutableDictionary dictionaryWithContentsOfFile:propertyURL.path];
        } else {
            _property = [[NSMutableDictionary alloc] init];
        }
    }
    return _property;
}

- (void) saveProperty
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appDocsDir = [[fileManager URLsForDirectory:NSDocumentDirectory
                                             inDomains:NSUserDomainMask] lastObject];
    NSURL *propertyURL = [NSURL URLWithString:PROPERTY_FILE
                                relativeToURL:appDocsDir];
    [self.property writeToURL:propertyURL atomically:YES];
}

- (void) showError: (NSString *)errorStr
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Operation Failed"
                                                        message:errorStr
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

+ (NSString *) md5:(NSString *) input
{
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, (unsigned int)strlen(cStr), digest ); // This is the md5 call
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
}

+ (NSString *) buildGravatarURL:(NSString *) email
{
    NSString *hash = [SHBasic md5:email];
    NSString *url = [NSString stringWithFormat:@"http://www.gravatar.com/avatar/%@?s=50", hash];
    return url;
}

+ (BOOL) isDir:(NSString *)file
{
    BOOL isDir;
    [[NSFileManager defaultManager] fileExistsAtPath:file isDirectory:&isDir];
    return isDir;
}


@end

@implementation NSString (Paths)

- (NSString*)stringWithPathRelativeTo:(NSString*)anchorPath
{
    NSArray *pathComponents = [self pathComponents];
    NSArray *anchorComponents = [anchorPath pathComponents];
    
    NSInteger componentsInCommon = MIN([pathComponents count], [anchorComponents count]);
    for (NSInteger i = 0, n = componentsInCommon; i < n; i++) {
        if (![[pathComponents objectAtIndex:i] isEqualToString:[anchorComponents objectAtIndex:i]]) {
            componentsInCommon = i;
            break;
        }
    }
    
    NSUInteger numberOfParentComponents = [anchorComponents count] - componentsInCommon;
    NSUInteger numberOfPathComponents = [pathComponents count] - componentsInCommon;
    
    NSMutableArray *relativeComponents = [NSMutableArray arrayWithCapacity:
                                          numberOfParentComponents + numberOfPathComponents];
    for (NSInteger i = 0; i < numberOfParentComponents; i++) {
        [relativeComponents addObject:@".."];
    }
    [relativeComponents addObjectsFromArray:
     [pathComponents subarrayWithRange:NSMakeRange(componentsInCommon, numberOfPathComponents)]];
    return [NSString pathWithComponents:relativeComponents];
}

@end