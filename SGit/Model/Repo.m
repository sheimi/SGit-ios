//
//  Repo.m
//  SGit
//
//  Created by Rizhen Zhang on 12/26/13.
//  Copyright (c) 2013 Rizhen Zhang. All rights reserved.
//

#import "Repo.h"
#import <ObjectiveGit/ObjectiveGit.h>
#import "Commit.h"
#import "SHBasic.h"

# pragma defines

# pragma mark - c function declaration
typedef struct {
    __unsafe_unretained Repo *repo;
    __unsafe_unretained NSManagedObjectContext *context;
} clone_progress_data;


typedef struct {
    __unsafe_unretained Repo *repo;
    __unsafe_unretained UIProgressView *progress;
} git_fetch_progress_data;

typedef struct {
    __unsafe_unretained UIProgressView *progress;
} git_progress_data;

static int clone_fetch_progress(const git_transfer_progress *stats,
                         void *payload);

static void clone_checkout_progress(const char *path,
                             size_t cur,
                             size_t tot,
                             void *payload);

static int git_credentials(git_cred **cred,
                    const char *url,
                    const char *username_from_url,
                    unsigned int allowed_types,
                    void *payload);


static int git_fetch_progress_transfer_cb(const git_transfer_progress *stats, void *data);

static int git_packbuilder_progress_cb(int stage,
                                       unsigned int current,
                                       unsigned int total,
                                       void *payload);

static int git_push_transfer_progress_cb(unsigned int current,
                                         unsigned int total,
                                         size_t bytes,
                                         void* payload);

static int git_push_status_foreach_cb(const char *ref, const char *msg, void *data);


static void git_checkout_progress(const char *path,
                                  size_t cur,
                                  size_t tot,
                                  void *payload);

static dispatch_queue_t repoQueue = nil;

# pragma Repo Object

@interface Repo()

@property (nonatomic, assign, readonly) git_repository *git_repository;
@property (nonatomic, assign, readonly) git_index *git_index;
@property (nonatomic, assign, readonly) git_commit *git_latest_commit;

@end

@implementation Repo

@dynamic local_path;
@dynamic remote_url;
@dynamic repo_status;
@dynamic username;
@dynamic password;
@dynamic last_committer_uname;
@dynamic last_commiter_email;
@dynamic last_commit_date;
@dynamic last_commit_msg;

@synthesize git_repository = _git_repository;
@synthesize git_index = _git_index;
@synthesize git_latest_commit = _git_latest_commit;

NSString *const REPO_STATUS_NULL = @"";
NSString *const REPO_STATUS_WAITING_CLONE = @"cloning ... , 0, 0/0";
NSString *const REPO_DIR = @"repos";

+ (dispatch_queue_t)getRepoQueues
{
    if (repoQueue == nil) {
        repoQueue = dispatch_queue_create("repo queue", NULL);
    }
    return repoQueue;
}


+ (NSURL *)getRepoLocalURL:(NSString *)localName
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appDocsDir = [[fileManager URLsForDirectory:NSDocumentDirectory
                                             inDomains:NSUserDomainMask] lastObject];
    NSURL *repoDirURL = [NSURL URLWithString:REPO_DIR
                               relativeToURL:appDocsDir];
    if (![fileManager fileExistsAtPath:repoDirURL.path]) {
        [fileManager createDirectoryAtURL:repoDirURL
              withIntermediateDirectories:NO
                               attributes:nil
                                    error:nil];
    }
    NSString *repoPath = [NSString stringWithFormat:@"%@/%@", REPO_DIR, localName.lastPathComponent];
    NSURL *url = [NSURL URLWithString:repoPath
                        relativeToURL:repoDirURL];
    return url;
}

- (void)dealloc
{
	if (_git_repository != NULL) {
		git_repository_free(_git_repository);
		_git_repository = NULL;
	}
    if (_git_index != NULL) {
        git_index_free(_git_index);
        _git_index = NULL;
    }
    if (_git_latest_commit != NULL) {
        git_commit_free(_git_latest_commit);
        _git_latest_commit = NULL;
    }
}

- (git_repository *)git_repository
{
    if (_git_repository == NULL) {
        const char *path = [self getLocalURL].path.fileSystemRepresentation;
        git_repository_open(&_git_repository, path);
    }
    return _git_repository;
}

- (git_index *)git_index
{
    if (_git_index == NULL) {
        git_repository_index(&_git_index, self.git_repository);
    }
    return _git_index;
}

- (git_commit *)git_latest_commit
{
    if (_git_latest_commit == NULL) {
        git_reference *head;
        git_repository_head(&head, self.git_repository);
        const git_oid *oid = git_reference_target(head);
        git_commit_lookup(&_git_latest_commit, self.git_repository, oid);
        git_reference_free(head);
    }
    return _git_latest_commit;
}

- (void)invalidate_latest_commit
{
    if (_git_latest_commit == NULL)
        return;
    git_commit_free(_git_latest_commit);
    _git_latest_commit = NULL;
}

- (NSString *)displayName
{
    return self.local_path.lastPathComponent;
}

- (NSURL *)getLocalURL
{
    return [Repo getRepoLocalURL:self.local_path];
}

- (void)updateLastCommitMessageWithContext:(NSManagedObjectContext *)context
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self invalidate_latest_commit];
        Commit *commit = [Commit initWithCommit:self.git_latest_commit];
        self.last_commit_date = commit.dateStr;
        self.last_commiter_email = commit.committerEmail;
        self.last_committer_uname = commit.committerName;
        self.last_commit_msg = commit.message;
        [self saveInContext:context];
    });
}

- (void)cloneInContext:(NSManagedObjectContext *)context
{
    __weak Repo *_self = self;
    dispatch_async([Repo getRepoQueues], ^{
        git_repository* repo = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *localURL = [_self getLocalURL];
        NSLog(@"%@", localURL.path);
        if (![fileManager fileExistsAtPath:localURL.path]) {
            clone_progress_data payload;
            payload.repo = _self;
            payload.context = context;
            
            const char *remote = [_self.remote_url UTF8String];
            const char *local_url = [self getLocalURL].path.fileSystemRepresentation;
            git_clone_options clone_opts = GIT_CLONE_OPTIONS_INIT;
            git_checkout_opts checkout_opts = GIT_CHECKOUT_OPTS_INIT;
            
            checkout_opts.checkout_strategy = GIT_CHECKOUT_SAFE_CREATE;
            checkout_opts.progress_cb = clone_checkout_progress;
            checkout_opts.progress_payload = &payload;
            
            clone_opts.checkout_opts = checkout_opts;
            clone_opts.remote_callbacks.transfer_progress = clone_fetch_progress;
            clone_opts.remote_callbacks.payload = &payload;
            clone_opts.ignore_cert_errors = true;
            clone_opts.remote_callbacks.credentials = git_credentials;
            
            int error = git_clone(&repo, remote, local_url, &clone_opts);
            if (error != 0) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self deleteInContext:context];
                });
                [self showError:error];
                return;
            }
            _self.repo_status = REPO_STATUS_NULL;
            [_self updateLastCommitMessageWithContext: context];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSError *error;
                [context deleteObject:self];
                if (![context save:&error]) {
                    // TODO
                    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                    abort();
                }
                [[SHBasic defaultBasic] showError:@"Local repo exist"];
            });
        }
    });
}

- (void)deleteInContext:(NSManagedObjectContext *)context
{
    NSString *local = self.local_path;
    NSError *error;
    [context deleteObject:self];
    if (![context save:&error]) {
        // TODO
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    dispatch_async([Repo getRepoQueues], ^{
        [[NSFileManager defaultManager] removeItemAtURL:[Repo getRepoLocalURL:local]
                                                  error: nil];
    });
}

- (void)saveInContext:(NSManagedObjectContext *)context
{
    NSError *error;
    if (![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    if (context.parentContext != nil) {
        [self saveInContext:context.parentContext];
    }
}

- (NSArray *)getCommits
{
    git_reference *head;
    git_repository_head(&head, self.git_repository);
    const git_oid *oid = git_reference_target(head);
    git_oid woid = *oid;
    git_revwalk *walk;
    git_commit *wcommit;
    git_revwalk_new(&walk, self.git_repository);
    git_revwalk_sorting(walk, GIT_SORT_TOPOLOGICAL | GIT_SORT_REVERSE);
    git_revwalk_push(walk, &woid);
    NSMutableArray *commits = [[NSMutableArray alloc] init];
    
    while ((git_revwalk_next(&woid, walk)) == 0) {
        git_commit_lookup(&wcommit, self.git_repository, &woid);
        Commit *commit = [Commit initWithCommit:wcommit];
        [commits addObject: commit];
        git_commit_free(wcommit);
    }
    git_revwalk_free(walk);
    git_reference_free(head);
    return commits;
}

- (void)addRemote:(NSString *)remoteName
        remoteURL:(NSString *)url
{
    git_remote *remote;
    git_remote_create(&remote, self.git_repository, [remoteName UTF8String], [url UTF8String]);
    git_remote_save(remote);
    git_remote_free(remote);
}

- (void)resetRepo
{
    git_reference *head;
    git_repository_head(&head, self.git_repository);
    const git_oid *oid = git_reference_target(head);
    git_object *gobj;
    git_object_lookup(&gobj, self.git_repository, oid, GIT_OBJ_ANY);
    int error = git_reset(self.git_repository, gobj, GIT_RESET_HARD);
    if (error != 0) {
        [self showError:error];
        return;
    }
    git_object_free(gobj);
    git_reference_free(head);
}

- (void)addToStage: (NSString *)path
{
    NSString *relative = [path stringWithPathRelativeTo:[self getLocalURL].path];
    git_index_add_bypath(self.git_index, relative.fileSystemRepresentation);
    git_index_write(self.git_index);
}

- (void)deleteRepoFile: (NSString *)path
{
    BOOL isDir = [SHBasic isDir:path];
    [[NSFileManager defaultManager] removeItemAtPath:path
                                               error:nil];
    NSString *relative = [path stringWithPathRelativeTo:[self getLocalURL].path];
    if (isDir) {
        git_index_remove_directory(self.git_index, relative.fileSystemRepresentation, 0);
    } else {
        git_index_remove_bypath(self.git_index, relative.fileSystemRepresentation);
    }
    git_index_write(self.git_index);
}

- (void)commitChangesWithName:(NSString *)name
                        email:(NSString *)email
                      message:(NSString *)message
                  withContext:(NSManagedObjectContext *)context
{
    git_oid commit_id;
    git_signature *author;
    git_tree* tree = NULL;
    NSDate * now = [NSDate date];
    git_signature_new(&author,
                      [name UTF8String],
                      [email UTF8String],
                      [now timeIntervalSince1970], 0);
    git_oid tree_id;
    int error = git_index_write_tree(&tree_id, self.git_index);
    if (error != 0) {
        [self showError:error];
        goto error_handle;
    }
    git_tree_lookup(&tree, self.git_repository, &tree_id);
    git_commit_create_v(&commit_id,
                        self.git_repository,
                        @"HEAD".UTF8String,
                        author,
                        author,
                        "UTF-8",
                        message.UTF8String,
                        tree,
                        1, self.git_latest_commit);
    // TODO handle error
error_handle:
    git_signature_free(author);
    git_tree_free(tree);
    [self updateLastCommitMessageWithContext:context];
}

- (void)mergeWith:(NSString *)branch
     withProgress:(UIProgressView *) progress
      withContext:(NSManagedObjectContext *)context
{
    NSString *branchType = branch.lastPathComponent;
    NSString *branchName = branch.stringByDeletingLastPathComponent;
    git_branch_t branch_type = [branchType isEqualToString:@"local"]? GIT_BRANCH_LOCAL : GIT_BRANCH_REMOTE;
    
    git_merge_head *merge_head;
    git_reference *branch_ref;
    git_branch_lookup(&branch_ref, self.git_repository, branchName.UTF8String, branch_type);
    git_merge_head_from_ref(&merge_head, self.git_repository, branch_ref);
    
    git_progress_data payload;
    payload.progress = progress;
    
    git_merge_opts opts = GIT_MERGE_OPTS_INIT;
    opts.checkout_opts.progress_cb = git_checkout_progress;
    opts.checkout_opts.progress_payload = &payload;
    
    git_merge_result *merge_result;
    git_merge(&merge_result, self.git_repository, &merge_head, 1, &opts);
    
    if (git_merge_result_is_fastforward(merge_result)) {
        NSString *current = [self getCurrentBranch];
        git_reference *current_ref;
        git_reference_lookup(&current_ref, self.git_repository, current.UTF8String);
        git_oid oid;
        git_merge_result_fastforward_oid(&oid, merge_result);
        git_reference *new_ref;
        git_reference_set_target(&new_ref, current_ref, &oid);
        git_reference_free(new_ref);
        git_reference_free(current_ref);
        [self resetRepo];
    }
    git_reference_free(branch_ref);
    git_merge_head_free(merge_head);
    [self updateLastCommitMessageWithContext:context];
}

- (void)fetchWithProgress:(UIProgressView *)progress
{
    [self fetchFromRemote: @"origin" withProgress:progress];
}

- (void)fetchFromRemote:(NSString *)remoteName
           withProgress:(UIProgressView *)progress
{
    git_remote *remote;
    git_remote_load(&remote, self.git_repository, remoteName.UTF8String);
    
    git_remote_callbacks callbacks = GIT_REMOTE_CALLBACKS_INIT;
    callbacks.transfer_progress = git_fetch_progress_transfer_cb;
    callbacks.credentials = git_credentials;
    git_fetch_progress_data payload;
    payload.progress = progress;
    payload.repo = self;
    callbacks.payload = &payload;
    
    git_remote_set_callbacks(remote, &callbacks);
    git_remote_check_cert(remote, false);
    git_remote_fetch(remote);
    git_remote_free(remote);
    // TODO handle error
}

- (NSArray *)getBranches
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSString *currentBranch = [self getCurrentBranch].lastPathComponent;
    git_branch_iterator *iter;
    git_reference *branch;
    git_branch_t branch_type;
    const char *branch_name;
    NSMutableDictionary *branches = [[NSMutableDictionary alloc] init];
    git_branch_iterator_new(&iter, self.git_repository, GIT_BRANCH_LOCAL);
    while (GIT_ITEROVER != git_branch_next(&branch, &branch_type, iter)) {
        git_branch_name(&branch_name, branch);
        NSString *name = [NSString stringWithUTF8String:branch_name];
        NSString *value = [NSString stringWithFormat:@"%s/local", branch_name];
        [branches setObject:value forKey:name];
        git_reference_free(branch);
        if ([name isEqualToString:currentBranch])
            continue;
        [result addObject:value];
    }
    git_branch_iterator_free(iter);
    
    git_branch_iterator_new(&iter, self.git_repository, GIT_BRANCH_REMOTE);
    while (GIT_ITEROVER != git_branch_next(&branch, &branch_type, iter)) {
        git_branch_name(&branch_name, branch);
        NSString *name = [NSString stringWithUTF8String:branch_name];
        if ([branches objectForKey:name.lastPathComponent] != nil) {
            git_reference_free(branch);
            continue;
        }
        NSString *value = [NSString stringWithFormat:@"%s/remotes", branch_name];
        [result addObject:value];
        git_reference_free(branch);
    }
    git_branch_iterator_free(iter);
    
    return result;
}

- (void)checkOut:(NSString *)name
    withProgress:(UIProgressView *)progress
     withContext:(NSManagedObjectContext *)context
{
    git_oid oid;
    NSString *headref = nil;
    if ([name hasSuffix:@"remotes"]) {
        NSString *branch_name = [name stringByDeletingLastPathComponent];
        git_reference *refence;
        git_commit *commit;
        git_branch_lookup(&refence, self.git_repository,
                          branch_name.UTF8String,
                          GIT_BRANCH_REMOTE);
        const git_oid *oidp = git_reference_target(refence);
        git_commit_lookup(&commit, self.git_repository, oidp);
        git_reference_free(refence);
        
        git_branch_create(&refence, self.git_repository,
                          branch_name.lastPathComponent.UTF8String, commit, true);
        git_commit_free(commit);
        oid = *git_reference_target(refence);
        git_reference_free(refence);
        headref = [NSString stringWithFormat:@"refs/heads/%@", branch_name.lastPathComponent];
    } else if ([name hasSuffix:@"local"]) {
        git_reference *refence;
        NSString *branch_name = [name stringByDeletingLastPathComponent];
        git_branch_lookup(&refence, self.git_repository,
                          [name stringByDeletingLastPathComponent].UTF8String,
                          GIT_BRANCH_LOCAL);
        oid = *git_reference_target(refence);
        git_reference_free(refence);
        headref = [NSString stringWithFormat:@"refs/heads/%@", branch_name];
    } else {
        git_oid_fromstr(&oid, name.UTF8String);
        headref = name;
    }
    git_object *obj;
    git_object_lookup(&obj, self.git_repository, &oid, GIT_OBJ_ANY);
    
    git_progress_data payload;
    payload.progress = progress;
    
    git_checkout_opts opts = GIT_CHECKOUT_OPTS_INIT;
    opts.checkout_strategy = GIT_CHECKOUT_SAFE;
    opts.progress_cb = git_checkout_progress;
    opts.progress_payload = &payload;
    
    git_checkout_tree(self.git_repository, obj, &opts);
    
    git_object_free(obj);
    int error;
    if ([name hasSuffix:@"remotes"] || [name hasSuffix:@"local"]) {
        error = git_repository_set_head(self.git_repository, headref.UTF8String);
    } else {
        error =git_repository_set_head_detached(self.git_repository, &oid);
    }
    if (error) NSLog(@"error %d", error);
    [self updateLastCommitMessageWithContext:context];
}

- (void)push:(NSArray *)branches
          to:(NSString *)remoteName
withProgress:(UIProgressView *)progress
{
    git_push *push;
    git_remote *remote;
    git_remote_load(&remote, self.git_repository, remoteName.UTF8String);
    
    git_remote_callbacks callbacks = GIT_REMOTE_CALLBACKS_INIT;
    git_progress_data progress_payload;
    progress_payload.progress = progress;
    git_push_new(&push, remote);
    git_push_set_callbacks(push, git_packbuilder_progress_cb, NULL,
                           git_push_transfer_progress_cb, &progress_payload);
    
    callbacks.credentials = git_credentials;
    git_remote_check_cert(remote, false);
    clone_progress_data payload;
    payload.repo = self;
    callbacks.payload = &payload;
    
    git_remote_set_callbacks(remote, &callbacks);
    
    for (NSString *branch in branches) {
        git_push_add_refspec(push, branch.UTF8String);
    }
    
    int error = git_push_finish(push);
    git_push_status_foreach(push, git_push_status_foreach_cb, NULL);
    git_push_free(push);
    git_remote_free(remote);
    
    if (error != 0) {
        const git_error *e = giterr_last();
        NSLog(@"Error %d/%d: %s", error, e->klass, e->message);
        return;
    }
}

- (NSString *)status
{
    NSMutableString *buffer = [[NSMutableString alloc] init];
    NSString *branchStr = [self getCurrentBranch].lastPathComponent;
    [buffer appendFormat:@"On branch %@\n", branchStr];
    
    git_status_options opt = GIT_STATUS_OPTIONS_INIT;
    opt.show  = GIT_STATUS_SHOW_INDEX_AND_WORKDIR;
    opt.flags = GIT_STATUS_OPT_INCLUDE_UNTRACKED |
                GIT_STATUS_OPT_RENAMES_HEAD_TO_INDEX |
                GIT_STATUS_OPT_SORT_CASE_SENSITIVELY;
    git_status_list *status;
    git_status_list_new(&status, self.git_repository, &opt);
    const git_status_entry *s;
    bool changed_in_workdir = false, rm_in_workdir = false;
    bool header = false, changes_in_index = false;
    const char *old_path, *new_path;
    
    size_t max = git_status_list_entrycount(status);
    int i;
    for (i = 0; i < max; i++) {
        char *istatus = NULL;
        s = git_status_byindex(status, i);
        if (s->status == GIT_STATUS_CURRENT)
            continue;
        if (s->status & GIT_STATUS_WT_DELETED)
            rm_in_workdir = 1;
        if (s->status & GIT_STATUS_INDEX_NEW)
            istatus = "new file: ";
        if (s->status & GIT_STATUS_INDEX_MODIFIED)
            istatus = "modified: ";
        if (s->status & GIT_STATUS_INDEX_DELETED)
            istatus = "deleted:  ";
        if (s->status & GIT_STATUS_INDEX_RENAMED)
            istatus = "renamed:  ";
        if (s->status & GIT_STATUS_INDEX_TYPECHANGE)
            istatus = "typechange:";
        if (istatus == NULL)
            continue;
        if (!header) {
            [buffer appendString: @"# Changes to be committed:\n"];
            [buffer appendString: @"#   (use \"git reset HEAD <file>...\" to unstage)\n"];
            [buffer appendString: @"#\n"];
            header = true;
            changes_in_index = true;
        }
        old_path = s->head_to_index->old_file.path;
        new_path = s->head_to_index->new_file.path;
        if (old_path && new_path && strcmp(old_path, new_path))
            [buffer appendFormat:@"#\t%s  %s -> %s\n", istatus, old_path, new_path];
        else
            [buffer appendFormat:@"#\t%s  %s\n", istatus, old_path ? old_path : new_path];
        
    }
    
    if (header) {
        [buffer appendString: @"#\n"];
        changes_in_index = true;
    }
    
    header = false;
    
    for (i = 0; i < max; ++i) {
        char *wstatus = NULL;
        s = git_status_byindex(status, i);
        if (s->status == GIT_STATUS_CURRENT || s->index_to_workdir == NULL)
            continue;
        if (s->status & GIT_STATUS_WT_MODIFIED)
            wstatus = "modified: ";
        if (s->status & GIT_STATUS_WT_DELETED)
            wstatus = "deleted:  ";
        if (s->status & GIT_STATUS_WT_RENAMED)
            wstatus = "renamed:  ";
        if (s->status & GIT_STATUS_WT_TYPECHANGE)
            wstatus = "typechange:";
        
        if (wstatus == NULL)
            continue;
        
        if (!header) {
            [buffer appendString:@"# Changes not staged for commit:\n"];
            [buffer appendFormat:@"#   (use \"git add%s <file>...\" to update what will be committed)\n", rm_in_workdir ? "/rm" : ""];
            [buffer appendString:@"#   (use \"git checkout -- <file>...\" to discard changes in working directory)\n"];
            [buffer appendString: @"#\n"];
            header = true;
        }
        old_path = s->index_to_workdir->old_file.path;
        new_path = s->index_to_workdir->new_file.path;
        
        if (old_path && new_path && strcmp(old_path, new_path))
            [buffer appendFormat:@"#\t%s  %s -> %s\n", wstatus, old_path, new_path];
        else
            [buffer appendFormat:@"#\t%s  %s\n", wstatus, old_path ? old_path : new_path];
    }
    
    if (header) {
        changed_in_workdir = true;
        printf("#\n");
    }
    
    header = false;
    
    for (i = 0; i < max; ++i) {
        s = git_status_byindex(status, i);
        
        if (s->status == GIT_STATUS_WT_NEW) {
            
            if (!header) {
                [buffer appendString: @"# Untracked files:\n"];
                [buffer appendString: @"#   (use \"git add <file>...\" to include in what will be committed)\n"];
                [buffer appendString: @"#\n"];
                header = true;
            }
            [buffer appendFormat:@"#\t%s\n", s->index_to_workdir->old_file.path];
        }
    }
    
    for (i = 0; i < max; ++i) {
        s = git_status_byindex(status, i);
        
        if (s->status == GIT_STATUS_IGNORED) {
            
            if (!header) {
                [buffer appendString: @"# Ignored files:\n"];
                [buffer appendString: @"#   (use \"git add -f <file>...\" to include in what will be committed)\n"];
                [buffer appendString: @"#\n"];
                header = true;
            }
            [buffer appendFormat:@"#\t%s\n", s->index_to_workdir->old_file.path];
        }
    }
    
    if (!changes_in_index && changed_in_workdir)
        [buffer appendString: @"no changes added to commit (use \"git add\" and/or \"git commit -a\")\n"];
    
    if (!changes_in_index && !changed_in_workdir)
        [buffer appendString:@"nothing to commit, working directory clean\n"];
    
    git_status_list_free(status);
    return buffer;
}

# pragma mark -help methods
- (NSString *) getCurrentBranch
{
    
    git_reference *ref;
    git_reference_lookup(&ref, self.git_repository, "HEAD");
    const char *branch_name = git_reference_symbolic_target(ref);
    NSString *name = [NSString stringWithUTF8String:branch_name];
    git_reference_free(ref);
    return name;
}

- (void) showError:(int)error
{
    const git_error *e = giterr_last();
    NSString *errorStr = [NSString stringWithUTF8String:e->message];
    NSLog(@"Error %d/%d: %s", error, e->klass, e->message);
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[SHBasic defaultBasic] showError:errorStr];
    });
}

# pragma mark - c function implementation

# pragma mark - callbacks for clone
static int clone_fetch_progress(const git_transfer_progress *stats,
                         void *payload)
{
    clone_progress_data *pd = (clone_progress_data *)payload;
    NSManagedObjectContext *context = pd->context;
    Repo *repo = pd->repo;
    
    int total = stats->total_objects;
    int complete = stats->indexed_objects;
    int pg = complete * 100 / total;
    NSString *status = @"transfering objects ... ";
    repo.repo_status = [NSString stringWithFormat:@"%@, %d, %d/%d", status, pg, complete, total];
    [repo performSelectorOnMainThread:@selector(saveInContext:)
                            withObject:context
                         waitUntilDone:YES];
    return 0;
}

static void clone_checkout_progress(const char *path,
                             size_t cur,
                             size_t tot,
                             void *payload)
{
    clone_progress_data *pd = (clone_progress_data *)payload;
    NSManagedObjectContext *context = pd->context;
    Repo *repo = pd->repo;
    
    repo.repo_status = [NSString stringWithFormat:@"checking out ... , %d, %d/%d",
                        (int)(cur * 100 / tot), (int)cur, (int)tot];
    [repo performSelectorOnMainThread:@selector(saveInContext:)
                           withObject:context
                        waitUntilDone:YES];
    
}

static int git_credentials(git_cred **cred,
                    const char *url,
                    const char *username_from_url,
                    unsigned int allowed_types,
                    void *payload)
{
    SHBasic *basic = [SHBasic defaultBasic];
    clone_progress_data *pd = (clone_progress_data *)payload;
    Repo *repo = pd->repo;
    if (allowed_types & GIT_CREDTYPE_SSH_KEY) {
        NSString *urlStr = [NSString stringWithUTF8String:url];
        NSString *user = [urlStr componentsSeparatedByString:@"@"][0];
        NSDictionary *keyPair = [basic keyPairByKeyName:basic.defaultKeyPair];
        NSString *passphrase = [keyPair objectForKey:@"passphrase"];
        git_cred_ssh_key_new(cred, user.lastPathComponent.UTF8String, basic.defaultPublicKeyPath.UTF8String,
                             basic.defaultPrivateKeyPath.UTF8String, passphrase.UTF8String);
        return 0;
    }
    if (allowed_types & GIT_CREDTYPE_USERPASS_PLAINTEXT) {
        const char *username = [repo.username UTF8String];
        const char *password = [repo.password UTF8String];
        git_cred_userpass_plaintext_new(cred, username, password);
        return 0;
    }
    return 0;
}

static int git_fetch_progress_transfer_cb(const git_transfer_progress *stats, void *data)
{
    git_fetch_progress_data *pd = (git_fetch_progress_data *)data;
    int total = stats->total_objects;
    int complete = stats->indexed_objects;
    float percent = complete * 1.0 / total;
    dispatch_sync(dispatch_get_main_queue(), ^{
        pd->progress.progress = percent;
    });
    return 0;
}

static int git_packbuilder_progress_cb(int stage,
                                       unsigned int current,
                                       unsigned int total,
                                       void *payload)
{
    return 0;
}

static int git_push_transfer_progress_cb(unsigned int current,
                                         unsigned int total,
                                         size_t bytes,
                                         void* payload)
{
    git_progress_data *data = (git_progress_data *)payload;
    if (total == 0)
        return 0;
    float percent = current * 1.0 / total;
    dispatch_sync(dispatch_get_main_queue(), ^{
        data->progress.progress = percent;
    });
    return 0;
}

static int git_push_status_foreach_cb(const char *ref, const char *msg, void *data)
{
    NSLog(@"%s: %s", ref, msg);
    return 0;
}

static void git_checkout_progress(const char *path,
                                  size_t cur,
                                  size_t tot,
                                  void *payload)
{
    git_progress_data *data = (git_progress_data *)payload;
    if (tot == 0)
        return;
    float percent = cur * 1.0 / tot;
    dispatch_sync(dispatch_get_main_queue(), ^{
        data->progress.progress = percent;
    });
}


@end
