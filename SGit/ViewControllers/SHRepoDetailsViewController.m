//
//  SHRepoDetailsViewController.m
//  SGit
//
//  Created by Rizhen Zhang on 12/30/13.
//  Copyright (c) 2013 Rizhen Zhang. All rights reserved.
//

#import "SHRepoDetailsViewController.h"
#import "SHFilesViewController.h"
#import "SHCommitsViewController.h"
#import "SHAddRemoteViewController.h"
#import "SHCommitChangesViewController.h"
#import "SHShowBranchViewController.h"
#import "SHStatusViewController.h"

#define ALERT_DELETE_REPO_TAG 0

@interface SHRepoDetailsViewController()<UIActionSheetDelegate, UIAlertViewDelegate, SHShowBranchViewControllerDelegate, SHCommitChangesViewControllerDelegate>

@property (nonatomic, strong) NSMutableDictionary *actionDict;
@property (nonatomic, weak) SHFilesViewController *fileviewController;
@property (nonatomic, weak) SHCommitsViewController *commitViewController;
@property (nonatomic, weak) UIProgressView *progress;
@property (nonatomic, strong) NSString *currentOp;

@end

static NSArray *OP_ACTIONS = nil;

@implementation SHRepoDetailsViewController

@synthesize actionDict = _actionDict;

- (NSMutableDictionary *) actionDict {
    if (_actionDict == nil) {
        _actionDict = [[NSMutableDictionary alloc] init];
        [_actionDict setObject:[NSValue valueWithPointer:@selector(deleteRepo)]
                        forKey:@"Delete"];
        [_actionDict setObject:[NSValue valueWithPointer:@selector(newFile)]
                        forKey:@"New File"];
        [_actionDict setObject:[NSValue valueWithPointer:@selector(newDir)]
                        forKey:@"New Directory"];
        [_actionDict setObject:[NSValue valueWithPointer:@selector(addRemote)]
                        forKey:@"Add Remote"];
        [_actionDict setObject:[NSValue valueWithPointer:@selector(reset)]
                        forKey:@"Reset"];
        [_actionDict setObject:[NSValue valueWithPointer:@selector(commit)]
                        forKey:@"Commit"];
        [_actionDict setObject:[NSValue valueWithPointer:@selector(checkOut)]
                        forKey:@"Check Out"];
        [_actionDict setObject:[NSValue valueWithPointer:@selector(push)]
                        forKey:@"Push"];
        [_actionDict setObject:[NSValue valueWithPointer:@selector(fetch)]
                        forKey:@"Fetch"];
        [_actionDict setObject:[NSValue valueWithPointer:@selector(merge)]
                        forKey:@"Merge"];
    }
    return _actionDict;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.repo.displayName;
    for (UIViewController *v in self.viewControllers) {
        if ([v isKindOfClass:[SHFilesViewController class]]) {
            SHFilesViewController *vc = (SHFilesViewController *)v;
            vc.rootFilePath = [self.repo getLocalURL].path;
            vc.repo = self.repo;
            self.fileviewController = vc;
        } else if ([v isKindOfClass:[SHCommitsViewController class]]) {
            SHCommitsViewController *cc = (SHCommitsViewController *)v;
            cc.repo = self.repo;
            self.commitViewController = cc;
        } else if ([v isKindOfClass:[SHStatusViewController class]]) {
            SHStatusViewController *sc = (SHStatusViewController *)v;
            sc.repo = self.repo;
        }
    }
    
    // setup progress bar
    CGRect  viewRect = CGRectMake(0, 62, 320, 2);
    UIProgressView *progress = [[UIProgressView alloc] initWithFrame:viewRect];
    self.progress = progress;
    self.progress.alpha = 0;
    [self.navigationController.view addSubview:progress];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [self hideProgressBar];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.managedObjectContext = nil;
    self.repo = nil;
    [self.progress removeFromSuperview];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showOperationMenu:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Delete"
                                                    otherButtonTitles:@"Fetch",
                                  @"Push", @"Check Out", @"Commit", @"Reset", @"Merge",
                                  @"New File", @"New Directory", nil];
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

- (void)actionSheet:(UIActionSheet *) actionSheet
clickedButtonAtIndex: (NSInteger) buttonIndex {
    NSString *key = [actionSheet buttonTitleAtIndex:buttonIndex];
    NSValue *value = [self.actionDict objectForKey:key];
    if (value == nil)
        return;
    self.currentOp = key;
    SEL sel = [[self.actionDict objectForKey:key] pointerValue];
    ((void (*)(id, SEL))[self methodForSelector:sel])(self, sel); // like [self performSelector:sel];
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    self.title = @"";
}

- (void)actionSheet:(UIActionSheet *)actionSheet
willDismissWithButtonIndex:(NSInteger)buttonIndex {
    self.title = self.repo.displayName;
}

#pragma mark - Segue management

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"AddRemote"]) {
        SHAddRemoteViewController *ac = (SHAddRemoteViewController *)[segue.destinationViewController topViewController];
        ac.repo = self.repo;
    }
    if ([[segue identifier] isEqualToString:@"CommitChanges"]) {
        SHCommitChangesViewController *cc = (SHCommitChangesViewController *)[segue.destinationViewController topViewController];
        cc.delegate = self;
    }
    if ([[segue identifier] isEqualToString:@"ChooseBranch"]) {
        SHShowBranchViewController *sb = (SHShowBranchViewController *)[segue destinationViewController];
        sb.repo = self.repo;
        sb.title = self.currentOp;
        sb.delegate = self;
    }
}

#pragma mark - SHShowBranchViewControllerDelegate

- (void)branchSelected:(NSString *)branch {
    if ([self.currentOp isEqualToString:@"Check Out"]) {
        [self doCheckOut:branch];
        return;
    }
    if ([self.currentOp isEqualToString:@"Merge"]) {
        [self doMerge:branch];
    }
}

- (void)commitChangesViewController:(SHCommitChangesViewController *)controller
                  didFinishWithDone:(BOOL)done {
    if (done) {
        dispatch_async([Repo getRepoQueues], ^{
            [self.repo commitChangesWithName:controller.committerName.text
                                       email:controller.committerEmail.text
                                     message:controller.messageField.text
                                 withContext:self.managedObjectContext];
        });
        [self.commitViewController refreshCommits];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - UIAlertView
- (void)alertView:(UIAlertView *)alertView
didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == ALERT_DELETE_REPO_TAG) {
        if (![[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Delete"])
            return;
        [self.navigationController popToRootViewControllerAnimated:YES];
        [self.repo deleteInContext:self.managedObjectContext];
        return;
    }
}

#pragma mark - progress bar
- (void)showProgressBar {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.4];
    [self.progress setAlpha:1];
    [UIView commitAnimations];
}

- (void)hideProgressBar {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.4];
    [self.progress setAlpha:0];
    [UIView commitAnimations];
}

#pragma mark - git operations

- (void)deleteRepo {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Confirm Delete Repo"
                                                        message:@"Are you sure to delete this repo?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Delete", nil];
    alertView.tag = ALERT_DELETE_REPO_TAG;
    alertView.alertViewStyle = UIAlertViewStyleDefault;
    [alertView show];
}

- (void)newFile {
    [self.fileviewController newFile];
}

- (void)newDir {
    [self.fileviewController newDir];
}

- (void)addRemote {
    [self performSegueWithIdentifier:@"AddRemote" sender:self];
}

- (void)commit {
    [self performSegueWithIdentifier:@"CommitChanges" sender:self];
}

- (void)checkOut {
    [self performSegueWithIdentifier:@"ChooseBranch" sender:self];
}

- (void)merge {
    [self performSegueWithIdentifier:@"ChooseBranch" sender:self];
}

- (void)doCheckOut:(NSString *)branch {
    [self showProgressBar];
    dispatch_async([Repo getRepoQueues], ^{
        [self.repo checkOut: branch
               withProgress:self.progress
                withContext:self.managedObjectContext];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self hideProgressBar];
            [self.fileviewController refreshCurrentDirContent];
            [self.commitViewController refreshCommits];
        });
    });
}

- (void)doMerge:(NSString *)branch {
    [self showProgressBar];
    dispatch_async([Repo getRepoQueues], ^{
        [self.repo mergeWith: branch
               withProgress:self.progress
                 withContext:self.managedObjectContext];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self hideProgressBar];
            [self.fileviewController refreshCurrentDirContent];
            [self.commitViewController refreshCommits];
        });
    });
}

- (void)reset {
    __weak SHRepoDetailsViewController *_self = self;
    dispatch_async([Repo getRepoQueues], ^{
        [_self.repo resetRepo];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_self.fileviewController refreshCurrentDirContent];
        });
    });
}

- (void)push {
    [self showProgressBar];
    dispatch_async([Repo getRepoQueues], ^{
        [self.repo push:@[@"refs/heads/master"]
                     to:@"origin"
           withProgress:self.progress];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self hideProgressBar];
        });
    });
}

- (void)fetch {
    [self showProgressBar];
    dispatch_async([Repo getRepoQueues], ^{
        [self.repo fetchWithProgress:self.progress];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self hideProgressBar];
        });
    });
}

@end
