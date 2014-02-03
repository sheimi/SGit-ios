//
//  SHCommitChangesViewController.m
//  SGit
//
//  Created by Rizhen Zhang on 1/3/14.
//  Copyright (c) 2014 Rizhen Zhang. All rights reserved.
//

#import "SHCommitChangesViewController.h"
#import "SHBasic.h"

@interface SHCommitChangesViewController ()<UITextFieldDelegate>

@end

@implementation SHCommitChangesViewController

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
    [self.messageField becomeFirstResponder];
    [self loadCommitter];
    self.committerEmail.delegate = self;
    self.committerName.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)cancel:(id)sender {
    [self.delegate commitChangesViewController:self didFinishWithDone:NO];
}

- (IBAction)commitRepo:(id)sender {
    [self saveCommitter];
    [self.delegate commitChangesViewController:self didFinishWithDone:YES];
}

- (void)loadCommitter {
    SHBasic *basic = [SHBasic defaultBasic];
    NSString *git_name = [basic.property objectForKey:@"git.name"];
    git_name = git_name == nil ? @"" : git_name;
    NSString *git_email = [basic.property objectForKey:@"git.email"];
    git_email = git_email == nil ? @"" : git_email;
    if (![git_email isEqualToString:@""]) {
        self.committerEmail.text = git_email;
    } else {
        [self.messageField resignFirstResponder];
        [self.committerEmail becomeFirstResponder];
    }
    if (![git_name isEqualToString:@""]) {
        self.committerName.text = git_name;
    } else {
        [self.messageField resignFirstResponder];
        [self.committerEmail resignFirstResponder];
        [self.committerName becomeFirstResponder];
    }
    
}

- (void)saveCommitter {
    SHBasic *basic = [SHBasic defaultBasic];
    [basic.property setObject:self.committerName.text
                      forKey:@"git.name"];
    [basic.property setObject:self.committerEmail.text
                      forKey:@"git.email"];
    [basic saveProperty];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.committerName) {
        [self.committerEmail becomeFirstResponder];
        return NO;
    }
    if (textField == self.committerEmail) {
        [self.messageField becomeFirstResponder];
        return NO;
    }
    return YES;
}
@end
