//
//  SHAddRemoteViewController.m
//  SGit
//
//  Created by Rizhen Zhang on 1/2/14.
//  Copyright (c) 2014 Rizhen Zhang. All rights reserved.
//

#import "SHAddRemoteViewController.h"

@interface SHAddRemoteViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *remoteName;
@property (weak, nonatomic) IBOutlet UITextField *remoteUrl;

@end

@implementation SHAddRemoteViewController

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
    self.remoteName.delegate = self;
    self.remoteUrl.delegate = self;
    [self.remoteName becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)addRemote:(id)sender {
    NSString *name = self.remoteName.text;
    NSString *url = self.remoteUrl.text;
    [self.repo addRemote:name remoteURL:url];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.remoteName) {
        [self.remoteUrl becomeFirstResponder];
        return NO;
    }
    if (textField == self.remoteUrl) {
        [self addRemote:textField];
        return NO;
    }
    return YES;
}

@end
