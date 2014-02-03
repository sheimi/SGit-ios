//
//  SHPrivateKeyViewController.h
//  SGit
//
//  Created by Rizhen Zhang on 2/1/14.
//  Copyright (c) 2014 Rizhen Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SHPrivateKeyViewControllerDelegate;

@interface SHPrivateKeyViewController : UITableViewController

@property (nonatomic, weak) id<SHPrivateKeyViewControllerDelegate> delegate;

@end

@protocol SHPrivateKeyViewControllerDelegate

@end