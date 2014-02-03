//
//  SHRepoCommitCell.h
//  SGit
//
//  Created by Rizhen Zhang on 1/1/14.
//  Copyright (c) 2014 Rizhen Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHRepoCommitCell : UITableViewCell

@property (weak, nonatomic, readonly) UILabel *commitHash;
@property (weak, nonatomic, readonly) UIImageView *image;
@property (weak, nonatomic, readonly) UILabel *committer;
@property (weak, nonatomic, readonly) UILabel *time;
@property (weak, nonatomic, readonly) UILabel *message;

@end
