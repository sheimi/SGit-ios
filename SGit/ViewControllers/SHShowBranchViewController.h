//
//  SHShowBranchViewController.h
//  SGit
//
//  Created by Rizhen Zhang on 1/16/14.
//  Copyright (c) 2014 Rizhen Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Repo.h"


@protocol SHShowBranchViewControllerDelegate;

@interface SHShowBranchViewController : UIViewController

@property (nonatomic, strong) Repo *repo;
@property (nonatomic, weak) id<SHShowBranchViewControllerDelegate> delegate;

@end

@protocol SHShowBranchViewControllerDelegate

- (void)branchSelected:(NSString *)branch;

@end
