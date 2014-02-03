//
//  SHRepoListViewController.m
//  SGit
//
//  Created by Rizhen Zhang on 12/26/13.
//  Copyright (c) 2013 Rizhen Zhang. All rights reserved.
//

#import "SHRepoListViewController.h"
#import "Repo.h"
#import "SHCloneRepoViewController.h"
#import "SHRepoListCell.h"
#import "SHRepoListLoadingCell.h"
#import "SHRepoDetailsViewController.h"
#import "SHPrivateKeyViewController.h"
#import "UIImageView+WebCache.h"
#import "SHBasic.h"

#define ALERT_DELETE_REPO_TAG 0

@interface SHRepoListViewController () <SHCloneRepoViewControllerDelegate, NSFetchedResultsControllerDelegate, UITableViewDataSource, MSCMoreOptionTableViewCellDelegate, UIAlertViewDelegate, UIActionSheetDelegate, SHPrivateKeyViewControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, weak) NSIndexPath *indexPathToDelete;

@end

@implementation SHRepoListViewController

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
	// Do any additional setup after loading the view.
    [self.tableView setDataSource:self];
    
    NSError *error;
    if (![[self fetchedResultsController] performFetch:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (void)viewWillAppear: (BOOL)animated{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}


- (void)viewDidUnload {
    [super viewDidUnload];
    self.fetchedResultsController = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    // Create and configure a fetch request with the Book entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Repo"
                                              inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Create the sort descriptors array.
    NSSortDescriptor *localPathDescriptor = [[NSSortDescriptor alloc] initWithKey:@"local_path" ascending:YES];
    NSArray *sortDescriptors = @[localPathDescriptor];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Create and initialize the fetch results controller.
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:self.managedObjectContext
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:@"Root"];
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
}


- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    UITableView *tableView = self.tableView;
    Repo *repo = (Repo *)anObject;
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            [repo cloneInContext:self.managedObjectContext];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            [tableView insertRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}

#pragma mark - Segue management

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"Clone"]) {
      
        SHCloneRepoViewController *cloneRepoViewController = (SHCloneRepoViewController *)[[segue destinationViewController] topViewController];
        cloneRepoViewController.delegate = self;
        
        NSManagedObjectContext *cloneContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [cloneContext setParentContext:[self.fetchedResultsController managedObjectContext]];
        
        Repo *repo = (Repo *)[NSEntityDescription insertNewObjectForEntityForName:@"Repo"
                                                           inManagedObjectContext:cloneContext];

        cloneRepoViewController.repo = repo;
        cloneRepoViewController.managedObjectContext = cloneContext;
        return;
    }
    
    if ([[segue identifier] isEqualToString:@"ShowRepoDetails"]) {
        SHRepoDetailsViewController *detailController = (SHRepoDetailsViewController *) [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Repo *repo = (Repo *)[self.fetchedResultsController objectAtIndexPath:indexPath];
        detailController.repo = repo;
        detailController.managedObjectContext = self.fetchedResultsController.managedObjectContext;
        return;
    }
    
    if ([[segue identifier] isEqualToString:@"showPrivateKey"]) {
        SHPrivateKeyViewController *pkvc = (SHPrivateKeyViewController *)[segue destinationViewController];
        pkvc.delegate = self;
        return;
    }
    
}

#pragma mark - Segue SHCloneRepoViewControllerDelegate
- (void)cloneRepoViewController:(SHCloneRepoViewController *)controller
        didFinishWithDone:(BOOL)done {
    if (done) {
        [controller.repo saveInContext:controller.managedObjectContext];
    }
    
    // Dismiss the modal view to return to the main list
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table view data source methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return [[self.fetchedResultsController sections] count];
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}



- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Repo *repo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if ([repo.repo_status isEqualToString:REPO_STATUS_NULL]) {
        SHRepoListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RepoCell"];
        cell.localPath.text = repo.displayName;
        cell.remoteUrl.text = repo.remote_url;
        cell.lastCommitter.text = repo.last_committer_uname;
        cell.lastCommitTime.text = repo.last_commit_date;
        cell.lastCommitMsg.text = repo.last_commit_msg;
        
        UIImage *image = [UIImage imageNamed:@"GravatarDefault"];
        NSURL *url = [NSURL URLWithString:[SHBasic buildGravatarURL:repo.last_commiter_email]];
        [cell.lastCommitterImg setImageWithURL:url
                              placeholderImage:image];
        
        //cell.delegate = self;
        return cell;
    }
    
    SHRepoListLoadingCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RepoLoadingCell"];
    NSArray *statusItems = [repo.repo_status componentsSeparatedByString:@", "];
    NSString *status = [statusItems objectAtIndex:0];
    NSString *precentStr = [statusItems objectAtIndex:1];
    NSString *fraction = [statusItems objectAtIndex:2];
    int precent = [precentStr intValue];
    cell.localPath.text = repo.displayName;
    cell.remoteUrl.text = repo.remote_url;
    cell.fraction.text = fraction;
    cell.percent.text = [NSString stringWithFormat:@"%d%%", precent];
    cell.msg.text = status;
    [cell.progress setProgress:precent / 100.0];
    return cell;
}


- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Confirm Delete Repo"
                                                            message:@"Are you sure to delete this repo?"
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Delete", nil];
        alertView.tag = ALERT_DELETE_REPO_TAG;
        alertView.alertViewStyle = UIAlertViewStyleDefault;
        [alertView show];
        [tableView setEditing:NO animated:YES];
        self.indexPathToDelete = indexPath;
    }
}

#pragma mark - UIAlertView
- (void)alertView:(UIAlertView *)alertView
didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == ALERT_DELETE_REPO_TAG) {
        if (![[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Delete"])
            return;
        
        // Delete the managed object.
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        Repo *repo = [self.fetchedResultsController objectAtIndexPath:self.indexPathToDelete];
        [repo deleteInContext:context];
        return;
    }
}

- (void)tableView:(UITableView *)tableView
moreOptionButtonPressedInRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView setEditing:NO animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView
titleForMoreOptionButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Info";
}

- (IBAction)showMenu:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Private Keys", nil];
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

- (void)actionSheet:(UIActionSheet *) actionSheet
clickedButtonAtIndex: (NSInteger) buttonIndex {
    NSString *key = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([key isEqualToString:@"Private Keys"]) {
        [self performSegueWithIdentifier:@"showPrivateKey" sender:self];
        return;
    }
}


@end
