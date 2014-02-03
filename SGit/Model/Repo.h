//
//  Repo.h
//  SGit
//
//  Created by Rizhen Zhang on 12/26/13.
//  Copyright (c) 2013 Rizhen Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Repo : NSManagedObject

@property (nonatomic, retain) NSString * local_path;
@property (nonatomic, retain) NSString * remote_url;
@property (nonatomic, retain) NSString * repo_status;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSString * last_committer_uname;
@property (nonatomic, retain) NSString * last_commiter_email;
@property (nonatomic, retain) NSString * last_commit_date;
@property (nonatomic, retain) NSString * last_commit_msg;

@property (nonatomic, readonly) NSString * displayName;

FOUNDATION_EXPORT NSString *const REPO_STATUS_NULL;
FOUNDATION_EXPORT NSString *const REPO_STATUS_WAITING_CLONE;

- (void)cloneInContext:(NSManagedObjectContext *)context;

- (void)deleteInContext:(NSManagedObjectContext *)context;

- (void)saveInContext:(NSManagedObjectContext *)context;

- (NSURL *)getLocalURL;

- (NSArray *)getCommits;

- (void)resetRepo;

- (void)deleteRepoFile: (NSString *)path;

- (void)addToStage: (NSString *)path;

- (void)addRemote:(NSString *)remote
        remoteURL:(NSString *)url;

- (void)commitChangesWithName:(NSString *)name
                        email:(NSString *)email
                      message:(NSString *)message
                  withContext:(NSManagedObjectContext *)context;

- (void)fetchWithProgress:(UIProgressView *)progress;

- (void)fetchFromRemote:(NSString *)remoteName
           withProgress:(UIProgressView *)progress;

- (void)checkOut:(NSString *)name
    withProgress:(UIProgressView *)progress
     withContext:(NSManagedObjectContext *)context;

- (NSArray *)getBranches;

- (void)push:(NSArray *)branches
          to:(NSString *)remoteName
withProgress:(UIProgressView *)progress;

- (void)mergeWith:(NSString *)branch
     withProgress:(UIProgressView *)progress
      withContext:(NSManagedObjectContext *)context;

- (NSString *)status;

+ (dispatch_queue_t)getRepoQueues;

+ (NSURL *)getRepoLocalURL:(NSString *) repoLocalPath;

@end
