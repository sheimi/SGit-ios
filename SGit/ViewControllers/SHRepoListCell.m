//
//  SHRepoListCell.m
//  SGit
//
//  Created by Rizhen Zhang on 12/26/13.
//  Copyright (c) 2013 Rizhen Zhang. All rights reserved.
//

#import "SHRepoListCell.h"
@interface SHRepoListCell ()

@property (weak, nonatomic) IBOutlet UILabel *localPath;
@property (weak, nonatomic) IBOutlet UILabel *remoteUrl;
@property (weak, nonatomic) IBOutlet UIImageView *lastCommitterImg;
@property (weak, nonatomic) IBOutlet UILabel *lastCommitter;
@property (weak, nonatomic) IBOutlet UILabel *lastCommitTime;
@property (weak, nonatomic) IBOutlet UILabel *lastCommitMsg;

@end

@implementation SHRepoListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
