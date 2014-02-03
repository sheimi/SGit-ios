//
//  SHCodeGuesser.h
//  SGit
//
//  Created by Rizhen Zhang on 12/30/13.
//  Copyright (c) 2013 Rizhen Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHCodeGuesser : NSObject

+ (NSString *)addSlash:(NSString *)raw;
+ (NSString *) guessLangForFileName:(NSString *)filename;
+ (NSArray *) getSupportLanguageList;
+ (NSString *) guessLangForExt:(NSString *)ext;

@end
