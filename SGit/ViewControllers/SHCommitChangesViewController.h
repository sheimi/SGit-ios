//
//  SHCommitChangesViewController.h
//  SGit
//
//  Created by Rizhen Zhang on 1/3/14.
//  Copyright (c) 2014 Rizhen Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Repo.h"


@protocol SHCommitChangesViewControllerDelegate;

@interface SHCommitChangesViewController : UITableViewController

@property (weak, nonatomic) id <SHCommitChangesViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UITextField *committerName;
@property (weak, nonatomic) IBOutlet UITextField *committerEmail;
@property (weak, nonatomic) IBOutlet UITextView *messageField;

@end

@protocol SHCommitChangesViewControllerDelegate

- (void)commitChangesViewController:(SHCommitChangesViewController *)controller
                  didFinishWithDone:(BOOL)done;

@end