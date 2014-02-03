//
//  SHViewFileViewController.h
//  SGit
//
//  Created by Rizhen Zhang on 12/30/13.
//  Copyright (c) 2013 Rizhen Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHViewFileViewController : UIViewController

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) Repo *repo;

@end
