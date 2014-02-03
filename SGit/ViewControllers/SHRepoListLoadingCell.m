//
//  SHRepoListLoadingCell.m
//  SGit
//
//  Created by Rizhen Zhang on 12/29/13.
//  Copyright (c) 2013 Rizhen Zhang. All rights reserved.
//

#import "SHRepoListLoadingCell.h"
@interface SHRepoListLoadingCell ()

@property (weak, nonatomic) IBOutlet UILabel *localPath;
@property (weak, nonatomic) IBOutlet UILabel *remoteUrl;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@property (weak, nonatomic) IBOutlet UILabel *msg;

@property (weak, nonatomic) IBOutlet UILabel *percent;
@property (weak, nonatomic) IBOutlet UILabel *fraction;

@end

@implementation SHRepoListLoadingCell

@end
