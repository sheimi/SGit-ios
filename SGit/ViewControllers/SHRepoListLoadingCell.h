//
//  SHRepoListLoadingCell.h
//  SGit
//
//  Created by Rizhen Zhang on 12/29/13.
//  Copyright (c) 2013 Rizhen Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHRepoListLoadingCell : UITableViewCell

@property (weak, nonatomic, readonly) UILabel *localPath;
@property (weak, nonatomic, readonly) UILabel *remoteUrl;
@property (weak, nonatomic, readonly) UIProgressView *progress;
@property (weak, nonatomic, readonly) UILabel *msg;
@property (weak, nonatomic, readonly) UILabel *percent;
@property (weak, nonatomic, readonly) UILabel *fraction;

@end
