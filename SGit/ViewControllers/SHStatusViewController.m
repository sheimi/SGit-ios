//
//  SHStatusViewController.m
//  SGit
//
//  Created by Rizhen Zhang on 2/1/14.
//  Copyright (c) 2014 Rizhen Zhang. All rights reserved.
//

#import "SHStatusViewController.h"

@interface SHStatusViewController ()
@property (weak, nonatomic) IBOutlet UITextView *statusContent;

@end

@implementation SHStatusViewController

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
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    self.statusContent.text = @"";
    dispatch_async([Repo getRepoQueues], ^{
        NSString *status = [self.repo status];
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.statusContent.text = status;
        });
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
