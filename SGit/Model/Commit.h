//
//  Commit.h
//  SGit
//
//  Created by Rizhen Zhang on 1/1/14.
//  Copyright (c) 2014 Rizhen Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ObjectiveGit/ObjectiveGit.h>

@interface Commit : NSObject

@property (strong, nonatomic) NSString *committerName;
@property (strong, nonatomic) NSString *committerEmail;
@property (strong, nonatomic) NSString *hashStr;
@property (strong, nonatomic) NSString *message;
@property (strong, nonatomic) NSDate *time;
@property (strong, nonatomic) NSString *dateStr;

+ (Commit *)initWithCommit: (git_commit *)commit;
- (NSString *)getShortHash;

@end
