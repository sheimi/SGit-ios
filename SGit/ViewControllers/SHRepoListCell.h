//
//  SHRepoListCell.h
//  SGit
//
//  Created by Rizhen Zhang on 12/26/13.
//  Copyright (c) 2013 Rizhen Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MSCMoreOptionTableViewCell.h"

@interface SHRepoListCell : UITableViewCell


@property (weak, nonatomic, readonly) UILabel *localPath;
@property (weak, nonatomic, readonly) UILabel *remoteUrl;
@property (weak, nonatomic, readonly) UIImageView *lastCommitterImg;
@property (weak, nonatomic, readonly) UILabel *lastCommitter;
@property (weak, nonatomic, readonly) UILabel *lastCommitTime;
@property (weak, nonatomic, readonly) UILabel *lastCommitMsg;

@end
