//
//  SHCloneRepoViewController.m
//  SGit
//
//  Created by Rizhen Zhang on 12/26/13.
//  Copyright (c) 2013 Rizhen Zhang. All rights reserved.
//

#import "SHCloneRepoViewController.h"
#import <ObjectiveGit/ObjectiveGit.h>

@interface SHCloneRepoViewController()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *remoteField;
@property (weak, nonatomic) IBOutlet UITextField *localField;
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;


@end

@implementation SHCloneRepoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.remoteField becomeFirstResponder];
    self.remoteField.delegate = self;
    self.localField.delegate = self;
    self.usernameField.delegate = self;
    self.passwordField.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelCloneRepo:(id)sender {
    [self.delegate cloneRepoViewController:self
                   didFinishWithDone:NO];
}

- (IBAction)cloneRepo:(id)sender {
    self.repo.remote_url = self.remoteField.text;
    self.repo.local_path = self.localField.text;
    self.repo.username = self.usernameField.text;
    self.repo.password = self.passwordField.text;
    self.repo.repo_status = REPO_STATUS_WAITING_CLONE;
    self.repo.last_commit_msg = @"";
    self.repo.last_commit_date = @"";
    self.repo.last_commiter_email = @"";
    self.repo.last_committer_uname = @"";

    [self.delegate cloneRepoViewController:self
                         didFinishWithDone:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.remoteField) {
        [self.localField becomeFirstResponder];
        return NO;
    }
    if (textField == self.localField) {
        [self.usernameField becomeFirstResponder];
        return NO;
    }
    if (textField == self.usernameField) {
        [self.passwordField becomeFirstResponder];
        return NO;
    }
    if (textField == self.passwordField) {
        [self cloneRepo:textField];
        return NO;
    }
    return YES;
}


@end
