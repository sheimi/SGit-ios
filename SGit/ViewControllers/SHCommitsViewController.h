//
//  SHCommitsViewController.h
//  SGit
//
//  Created by Rizhen Zhang on 1/1/14.
//  Copyright (c) 2014 Rizhen Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Repo.h"

@interface SHCommitsViewController : UIViewController

@property (nonatomic, strong) Repo *repo;

- (void) refreshCommits;

@end
