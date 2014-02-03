//
//  SHShowBranchViewController.m
//  SGit
//
//  Created by Rizhen Zhang on 1/16/14.
//  Copyright (c) 2014 Rizhen Zhang. All rights reserved.
//

#import "SHShowBranchViewController.h"

@interface SHShowBranchViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *branches;

@end

@implementation SHShowBranchViewController


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
    self.branches = [self.repo getBranches];
    [self.tableView reloadData];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return [self.branches count];
}

- (NSString *)objectAtIndexPath:(NSIndexPath *)indexPath {
    return [self.branches objectAtIndex:indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *branch = [self objectAtIndexPath:indexPath];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BranchCell"
                                                          forIndexPath:indexPath];
    cell.textLabel.text = branch.stringByDeletingLastPathComponent;
    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate branchSelected: [self objectAtIndexPath: indexPath ]];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
