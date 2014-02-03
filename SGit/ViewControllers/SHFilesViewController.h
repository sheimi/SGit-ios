//
//  SHFilesViewController.h
//  SGit
//
//  Created by Rizhen Zhang on 12/30/13.
//  Copyright (c) 2013 Rizhen Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Repo.h"

@interface SHFilesViewController : UIViewController

@property (nonatomic, strong) NSString *rootFilePath;
@property (nonatomic, strong) Repo *repo;

- (void)newDir;
- (void)newFile;
- (void) refreshCurrentDirContent;

@end
