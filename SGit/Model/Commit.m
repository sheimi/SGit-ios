//
//  Commit.m
//  SGit
//
//  Created by Rizhen Zhang on 1/1/14.
//  Copyright (c) 2014 Rizhen Zhang. All rights reserved.
//

#import "Commit.h"

#define BUFFER_SIZE_64 64
#define SHORT_HASH_LENGTH 10

@implementation Commit

@synthesize dateStr = _dateStr;


+ (Commit *)initWithCommit: (git_commit *)commit {
    Commit *c = [[self alloc] init];
    
    if (c != nil) {
        const git_signature *cauth = git_commit_committer(commit);
        const char *cmsg = git_commit_message(commit);
        const git_oid *oid = git_commit_id(commit);
        git_time_t time = git_commit_time(commit);
        char hash[BUFFER_SIZE_64];
        git_oid_tostr(hash, BUFFER_SIZE_64, oid);
        
        c.committerName = [NSString stringWithUTF8String:cauth->name];
        c.committerEmail = [NSString stringWithUTF8String:cauth->email];
        c.hashStr = [NSString stringWithUTF8String:hash];
        c.message = [NSString stringWithUTF8String:cmsg];
        c.time = [NSDate dateWithTimeIntervalSince1970:time];
        
    }
    
    return c;
}

- (NSString *)getShortHash {
    return [self.hashStr substringToIndex:SHORT_HASH_LENGTH];
}

- (NSString *)dateStr {
    if (_dateStr == nil) {
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"MM/dd/yyyy"];
        _dateStr = [dateFormat stringFromDate:self.time];
    }
    return _dateStr;
}

@end
