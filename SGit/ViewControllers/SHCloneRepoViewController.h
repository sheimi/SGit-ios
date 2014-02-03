//
//  SHCloneRepoViewController.h
//  SGit
//
//  Created by Rizhen Zhang on 12/26/13.
//  Copyright (c) 2013 Rizhen Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Repo.h"

@protocol SHCloneRepoViewControllerDelegate;

@interface SHCloneRepoViewController : UITableViewController

@property (nonatomic, strong) Repo *repo;
@property (nonatomic, weak) id <SHCloneRepoViewControllerDelegate> delegate;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@protocol SHCloneRepoViewControllerDelegate

- (void)cloneRepoViewController:(SHCloneRepoViewController *)controller
        didFinishWithDone:(BOOL)done;

@end