//
//  SHBasic.h
//  SGit
//
//  Created by Rizhen Zhang on 1/2/14.
//  Copyright (c) 2014 Rizhen Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHBasic : NSObject

@property (strong, nonatomic) NSMutableDictionary *property;
@property (strong, nonatomic) NSString *keyDir;
@property (strong, nonatomic) NSString *defaultKeyPair;
@property (strong, nonatomic, readonly) NSMutableDictionary *keyPairs;

+ (SHBasic *) defaultBasic;
- (void) saveProperty;

- (NSString *) privateKeyPath:(NSString *)keyName;
- (NSString *) publicKeyPath:(NSString *)name;
- (NSString *) defaultPrivateKeyPath;
- (NSString *) defaultPublicKeyPath;
- (void) removeKeyPair:(NSString *)name;
- (NSDictionary *) keyPairByKeyName: (NSString *)name;
- (void) setKeyPair: (NSDictionary *)keyPair
          byKeyName:(NSString *)name;
- (void) showError: (NSString *)errorStr;


+ (NSString *) buildGravatarURL:(NSString *) email;
+ (BOOL) isDir:(NSString *)file;
    
@end

@interface NSString (Paths)

- (NSString*)stringWithPathRelativeTo:(NSString*)anchorPath;

@end
