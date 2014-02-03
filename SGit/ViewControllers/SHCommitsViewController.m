//
//  SHCommitsViewController.m
//  SGit
//
//  Created by Rizhen Zhang on 1/1/14.
//  Copyright (c) 2014 Rizhen Zhang. All rights reserved.
//

#import "SHCommitsViewController.h"
#import "SHRepoDetailsViewController.h"
#import "Commit.h"
#import "SHRepoCommitCell.h"
#import "UIImageView+WebCache.h"
#import "SHBasic.h"

@interface SHCommitsViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSArray *commits;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
- (void) refreshCommits;

@end

@implementation SHCommitsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView reloadData];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self refreshCommits];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) refreshCommits {
    __weak SHCommitsViewController *_self = self;
    dispatch_async([Repo getRepoQueues], ^{
        _self.commits = [_self.repo getCommits];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_self.tableView reloadData];
        });
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    if (self.commits == nil)
        return 0;
    return [self.commits count];
}

- (Commit *)objectAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger count = [self.commits count];
    NSInteger index = count - indexPath.row - 1;
    return [self.commits objectAtIndex:index];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Commit *commit = [self objectAtIndexPath:indexPath];
    SHRepoCommitCell *cell = (SHRepoCommitCell *)[tableView dequeueReusableCellWithIdentifier:@"CommitCell"
                                                            forIndexPath:indexPath];
    cell.message.text = commit.message;
    cell.time.text = commit.dateStr;
    cell.commitHash.text = [commit getShortHash];
    cell.committer.text = commit.committerName;
    UIImage *image = [UIImage imageNamed:@"GravatarDefault"];
    NSURL *url = [NSURL URLWithString:[SHBasic buildGravatarURL:commit.committerEmail]];
    [cell.image setImageWithURL:url
                   placeholderImage:image];
    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Commit *commit = [self objectAtIndexPath:indexPath];
    SHRepoDetailsViewController *controller = (SHRepoDetailsViewController *)self.tabBarController;
    [controller doCheckOut:commit.hashStr];
}

@end
