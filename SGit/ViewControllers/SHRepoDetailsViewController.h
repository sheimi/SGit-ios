//
//  SHRepoDetailsViewController.h
//  SGit
//
//  Created by Rizhen Zhang on 12/30/13.
//  Copyright (c) 2013 Rizhen Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Repo.h"

@interface SHRepoDetailsViewController : UITabBarController

@property (nonatomic, strong) Repo *repo;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (void)doCheckOut:(NSString *)branch;

@end
