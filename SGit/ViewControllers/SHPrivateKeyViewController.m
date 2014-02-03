//
//  SHPrivateKeyViewController.m
//  SGit
//
//  Created by Rizhen Zhang on 2/1/14.
//  Copyright (c) 2014 Rizhen Zhang. All rights reserved.
//

#import "SHPrivateKeyViewController.h"
#import "SHEditKeyViewController.h"
#import "SHBasic.h"

@interface SHPrivateKeyViewController ()

@property (strong, nonatomic) NSMutableArray *keys;

@end

@implementation SHPrivateKeyViewController

@synthesize keys = _keys;

- (NSMutableArray *)keys {
    if (_keys == nil) {
        _keys = [[NSMutableArray alloc] init];
    }
    return _keys;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self reloadDir];
}

- (void)reloadDir {
    [self.keys removeAllObjects];
    SHBasic *basic = [SHBasic defaultBasic];
    NSDictionary *keyArray = [basic.property objectForKey:@"key.keys"];
    [keyArray enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self.keys addObject:key];
    }];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                  withRowAnimation:UITableViewRowAnimationFade];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return self.keys.count;
}

- (NSString *)getItemAt:(NSIndexPath *)indexPath
{
    return [self.keys objectAtIndex:indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"KeyCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    NSString *key = [self getItemAt:indexPath];
    cell.textLabel.text = key;
    SHBasic *basic = [SHBasic defaultBasic];
    if ([key isEqualToString:basic.defaultKeyPair]) {
        cell.detailTextLabel.text = @"default";
    } else {
        cell.detailTextLabel.text = @"";
    }
    return cell;
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"addKey"]) {
        SHEditKeyViewController *addKey = (SHEditKeyViewController *) [segue destinationViewController];
        addKey.title = @"Add key";
        return;
    }
    if ([[segue identifier] isEqualToString:@"editKey"]) {
        SHEditKeyViewController *editKey = (SHEditKeyViewController *) [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        editKey.key = [self getItemAt:indexPath];
        editKey.title = @"Edit key";
        return;
    }
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *keyName = [self getItemAt:indexPath];
        SHBasic *basic = [SHBasic defaultBasic];
        [basic removeKeyPair:keyName];
        [self.keys removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}


@end
