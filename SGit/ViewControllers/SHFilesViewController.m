//
//  SHFilesViewController.m
//  SGit
//
//  Created by Rizhen Zhang on 12/30/13.
//  Copyright (c) 2013 Rizhen Zhang. All rights reserved.
//

#import "SHFilesViewController.h"
#import "SHViewFileViewController.h"
#import "SHBasic.h"
#import "MSCMoreOptionTableViewCell.h"

#pragma mark - alert view tags

#define ALERT_CREATE_FILE_TAG 0
#define ALERT_CREATE_DIR_TAG 1
#define ALERT_MOVE_DIR_TAG 2


@interface SHFilesViewController ()<MSCMoreOptionTableViewCellDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong, setter = setCurrentDir:) NSString *currentDir;
@property (nonatomic, strong) NSMutableArray *currentDirContent;
@property (nonatomic, strong) NSIndexPath *currentIndexPath;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (void) setCurrentDir:(NSString *)dir;
- (void) refreshCurrentDirContent;

@end

@implementation SHFilesViewController

@synthesize currentDirContent = _currentDirContent;
@synthesize currentDir = _currentDir;

- (NSString *) getFullPath:(NSString *)path {
    return [NSString stringWithFormat:@"%@/%@", self.currentDir, path];
}

- (void) setCurrentDir:(NSString *)dir {
    if ([_currentDir isEqualToString:dir])
        return;
    if ([dir.lastPathComponent isEqualToString:@".."]) {
        dir = [_currentDir stringByDeletingLastPathComponent];
    }
    _currentDir = dir;
    [self refreshCurrentDirContent];
}

- (void) refreshCurrentDirContent {
    [self.currentDirContent removeAllObjects];
    NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_currentDir error:nil];
    if (![_currentDir isEqualToString:self.rootFilePath]) {
        [self.currentDirContent addObject:[self getFullPath:@".."]];
    }
    for (NSString *file in content) {
        [self.currentDirContent addObject:[self getFullPath:file]];
    }
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                  withRowAnimation:UITableViewRowAnimationFade];
}

- (NSMutableArray *) currentDirContent {
    if (_currentDirContent == nil) {
        _currentDirContent = [[NSMutableArray alloc] init];
    }
    return _currentDirContent;
}

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
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.currentDir = self.rootFilePath;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source & delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return [self.currentDirContent count];
}

- (NSString *)objectAtIndexPath:(NSIndexPath *)indexPath {
    return [self.currentDirContent objectAtIndex:indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *filePath = [self objectAtIndexPath:indexPath];
    NSString *CellIdentifier = [SHBasic isDir:filePath]? @"DirCell": @"FileCell";
    MSCMoreOptionTableViewCell *cell = (MSCMoreOptionTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                            forIndexPath:indexPath];
    cell.textLabel.text = filePath.lastPathComponent;
    cell.delegate = self;
    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *path = [self objectAtIndexPath:indexPath ];
    if ([SHBasic isDir:path]) {
        self.currentDir = path;
    }
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *path = [self objectAtIndexPath:indexPath];
        [self.currentDirContent removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath]
                         withRowAnimation:UITableViewRowAnimationAutomatic];
        __weak SHFilesViewController *_self = self;
        dispatch_async([Repo getRepoQueues], ^{
            [_self.repo deleteRepoFile:path];
        });
    }
}

#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ViewFileContent"]) {
        SHViewFileViewController *viewFileController = (SHViewFileViewController *) [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSString *path = [self objectAtIndexPath:indexPath];
        viewFileController.filePath = path;
        viewFileController.repo = self.repo;
    }
}

#pragma mark - create file and directory

- (void)newFile {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Create File"
                                                        message:@"Please enter your file name"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Create", nil];
    alertView.tag = ALERT_CREATE_FILE_TAG;
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView show];
}

- (void)newDir {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Create Directory"
                                                        message:@"Please enter your directory name"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Create", nil];
    alertView.tag = ALERT_CREATE_DIR_TAG;
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView
didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == ALERT_CREATE_FILE_TAG) {
        if (![[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Create"])
            return;
        UITextField *fileField = [alertView textFieldAtIndex:0];
        NSString *filepath = [self.currentDir stringByAppendingPathComponent:fileField.text];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filepath]) {
            [[SHBasic defaultBasic] showError:@"File Name Exists"];
            return;
        }
        [[NSData data] writeToFile:filepath
                           options:NSDataWritingAtomic
                             error:nil];
        [self refreshCurrentDirContent];
        [self.repo addToStage:filepath];
        return;
    }
    
    if (alertView.tag == ALERT_CREATE_DIR_TAG) {
        if (![[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Create"])
            return;
        UITextField *dirField = [alertView textFieldAtIndex:0];
        NSString *dirpath = [self.currentDir stringByAppendingPathComponent:dirField.text];
        if ([[NSFileManager defaultManager] fileExistsAtPath:dirpath]) {
            [[SHBasic defaultBasic] showError:@"Directory Name Exists"];
            return;
        }
        [[NSFileManager defaultManager] createDirectoryAtPath:dirpath
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:nil];
        [self refreshCurrentDirContent];
        return;
    }
    
    if (alertView.tag == ALERT_MOVE_DIR_TAG) {
        if (![[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Move"])
            return;
        UITextField *field = [alertView textFieldAtIndex:0];
        NSString *newPath = [self.currentDir stringByAppendingPathComponent:field.text];
        NSString *oldPath = [self objectAtIndexPath:self.currentIndexPath];
        oldPath = [self.currentDir stringByAppendingPathComponent:oldPath.lastPathComponent];
        NSError *error;
        if ([[NSFileManager defaultManager] fileExistsAtPath:newPath]) {
            [[SHBasic defaultBasic] showError:@"File Exists"];
            return;
        }
        BOOL isDir;
        if (![[NSFileManager defaultManager] fileExistsAtPath:newPath.stringByDeletingLastPathComponent
                                                 isDirectory:&isDir] || !isDir) {
            [[SHBasic defaultBasic] showError:@"Directory not exists"];
            return;
        }
        if (![[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:&error]) {
            [[SHBasic defaultBasic] showError:[NSString stringWithFormat:@"%@", error]];
            return;
        }
        [self.repo addToStage:newPath];
        [self.repo deleteRepoFile:oldPath];
        [self refreshCurrentDirContent];
        return;
    }
}

- (void)tableView:(UITableView *)tableView
moreOptionButtonPressedInRowAtIndexPath:(NSIndexPath *)indexPath {
    self.currentIndexPath = indexPath;
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Move to", nil];
    [actionSheet showInView:tableView];
    [tableView setEditing:NO animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView
titleForMoreOptionButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"More";
}

- (void)actionSheet:(UIActionSheet *) actionSheet
clickedButtonAtIndex: (NSInteger) buttonIndex {
    NSString *key = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([key isEqualToString:@"Move to"]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Move to "
                                                            message:@"Please enter destination name"
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Move", nil];
        alertView.tag = ALERT_MOVE_DIR_TAG;
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alertView show];
        return;
    }
}
@end
