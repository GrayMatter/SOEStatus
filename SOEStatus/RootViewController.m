//
//  RootViewController.m
//  SOEStatus
//
//  Created by Paul Lynch on 02/09/2011.
//  Copyright 2011 P & L Systems. All rights reserved.
//

#import "RootViewController.h"
#import "SOEStatusAPI.h"
#import "PRPAlertView.h"
#import "ServerViewController.h"
#import "PLActionSheet.h"
#import "SOEGame.h"
#import "PLFeedback.h"
#import "WatchServer.h"

@interface RootViewController ()

@property (nonatomic, strong) PLFeedback *plFeedback;

@end

NSString *SOEGameSelectedNotification = @"SOEGameSelectedNotification";

@implementation RootViewController

@synthesize statuses;

- (void)refresh {    
    [SOEStatusAPI getStatuses:^(PLRestful *api, id object, NSInteger status, NSError *error){
        if (error) {
            NSLog(@"API Error: %@", error);
            NSString *message = [NSString stringWithFormat:@"%@", [error localizedDescription]];
            [PRPAlertView showWithTitle:@"API Error" message:[NSString stringWithFormat:@"The SOE Status server isn't responding (%@).", message] buttonTitle:@"Continue"];
        }
        
        CGFloat height = 44.0 * [[SOEGame games] count];
        CGFloat maxHeight = self.tableView.superview.frame.size.height - self.tableView.frame.origin.y;
        maxHeight = [UIScreen mainScreen].bounds.size.height - self.navigationController.navigationBar.bounds.size.height - 100.0f;
        if (height > maxHeight) height = maxHeight;
        CGFloat width = self.contentSizeForViewInPopover.width;
        if (width == 0) width = 320.0;
        
        self.contentSizeForViewInPopover = CGSizeMake(width, height);
        self.preferredContentSize = self.contentSizeForViewInPopover;
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
        
        if (!error) [[WatchServer sharedInstance] notify];
    }];
}

- (void)editing {
    [self.tableView setEditing:![self.tableView isEditing] animated:YES];
    if (self.tableView.isEditing) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editing)];
        self.navigationItem.rightBarButtonItem = doneButton;
    } else {
        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editing)];
        self.navigationItem.rightBarButtonItem = editButton;
        [SOEGame save];
    }
}

- (IBAction)actions {
    UIBarButtonItem *item = self.navigationItem.leftBarButtonItem;
    self.plFeedback.viewToPresentSheet = item;
    NSArray *buttons = [NSArray arrayWithObjects:@"Open in Safari", @"Do you like this app?", @"Feedback", nil];
    [PLActionSheet actionSheetWithTitle:nil destructiveButtonTitle:nil buttons:buttons showFrom:item onDismiss:^(NSInteger buttonIndex){
        if (buttonIndex == [buttons indexOfObject:@"Open in Safari"]) {
            [self openInSafari];
        } else if (buttonIndex == [buttons indexOfObject:@"Do you like this app?"]) {
            [self.plFeedback like];
        } else if (buttonIndex == [buttons indexOfObject:@"Feedback"]) {
            [self.plFeedback feedback];
        }
    } onCancel:nil finally:nil];
}

- (IBAction)openInSafari {
    [PRPAlertView showWithTitle:@"Warning" message:@"This will open Mobile Safari with the SOE status page" cancelTitle:@"Cancel" cancelBlock:nil otherTitle:@"Continue" otherBlock:^(NSString *title){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.soe.com/status"]];
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Games";
    
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editing)];
    self.navigationItem.rightBarButtonItem = editButton;
    
    UIBarButtonItem *actionsButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actions)];
    self.navigationItem.leftBarButtonItem = actionsButton;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    // rater
    self.plFeedback = [[PLFeedback alloc] initWithViewController:self];
    [self.plFeedback checkForRating];
    
    CGFloat width = self.contentSizeForViewInPopover.width;
    if (width == 0) width = 320.0;
    self.contentSizeForViewInPopover = CGSizeMake(width, 44.0 * [[SOEGame games] count]);
    self.preferredContentSize = self.contentSizeForViewInPopover;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refresh];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    }
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[SOEGame games] count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    // Configure the cell.
    SOEGame *game = [[SOEGame games] objectAtIndex:indexPath.row];
    cell.textLabel.text = game.name ? game.name : game.key;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Delete the row from the data source.
        [SOEGame removeGame:[[SOEGame games] objectAtIndex:indexPath.row ]];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert)
    {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [SOEGame moveGameFromIndex:fromIndexPath.row to:toIndexPath.row];
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ServerViewController *detailViewController = [[ServerViewController alloc] initWithNibName:@"ServerViewController" bundle:nil];
    // ...
    // Pass the selected object to the new view controller.
    SOEGame *game = [[SOEGame games] objectAtIndex:indexPath.row];
    detailViewController.gameId = game.key;
    detailViewController.title = game.name;
    [self.navigationController pushViewController:detailViewController animated:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:SOEGameSelectedNotification object:self userInfo:@{@"game": game}];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    [self tableView:tableView didDeselectRowAtIndexPath:indexPath];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

@end
