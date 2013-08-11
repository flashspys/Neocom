//
//  BCSearchViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BCSearchViewController.h"
#import "GroupedCell.h"
#import "Globals.h"
#import "EVEDBAPI.h"
#import "BattleClinicAPI.h"
#import "Globals.h"
#import "UIAlertView+Error.h"
#import "BCSearchResultViewController.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"
#import "appearance.h"

@interface BCSearchViewController()
@property(nonatomic, strong) EVEDBInvType *ship;
@property(nonatomic, strong) NSArray *tags;
@property(nonatomic, strong) NSMutableArray *selectedTags;

- (void) testInputData;

@end


@implementation BCSearchViewController
@synthesize popoverController;


// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
 if (self) {
 // Custom initialization.
 }
 return self;
 }
 */


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];

	NSMutableArray *tagsTmp = [NSMutableArray array];
	self.title = NSLocalizedString(@"Search", nil);
	[self.navigationItem setRightBarButtonItem:self.searchButton];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.popoverController = [[UIPopoverController alloc] initWithContentViewController:self.modalController];
		self.popoverController.delegate = (FittingItemsViewController*)  self.modalController.topViewController;
	}
	else
		self.fittingItemsViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil)
																											style:UIBarButtonItemStyleBordered
																										   target:self
																										   action:@selector(didCloseModalViewController:)];

	if (!self.selectedTags)
		self.selectedTags = [[NSMutableArray alloc] init];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"BCSearchViewController+viewDidLoad" name:NSLocalizedString(@"Loading Tags", nil)];
	[operation addExecutionBlock:^{
		NSError *error = nil;
		BCEveLoadoutsTags *loadoutsTags = [BCEveLoadoutsTags eveLoadoutsTagsWithAPIKey:BattleClinicAPIKey error:&error progressHandler:nil];
		if (error) {
			[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
		}
		else {
			[tagsTmp addObjectsFromArray:[loadoutsTags.tags sortedArrayUsingSelector:@selector(compare:)]];
		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		self.tags = tagsTmp;
		[self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
	}];
	[[EUOperationQueue sharedQueue] addOperation:operation];
	[self testInputData];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.fittingItemsViewController = nil;
	self.modalController = nil;
	self.searchButton = nil;
	self.popoverController = nil;
	self.tags = nil;
}


- (IBAction) didCloseModalViewController:(id) sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction) onSearch:(id) sender {
	NSMutableArray *loadouts = [NSMutableArray array];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"BCSearchViewController+Search" name:NSLocalizedString(@"Searching...", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		NSError *error = nil;
		BCEveLoadoutsList *loadoutsList = [BCEveLoadoutsList eveLoadoutsListWithAPIKey:BattleClinicAPIKey raceID:0 typeID:self.ship.typeID classID:0 userID:0 tags:self.selectedTags error:&error progressHandler:nil];
		if (error) {
			[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
		}
		else {
			if (loadoutsList.loadouts.count == 0) {
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"Nothing found", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", nil) otherButtonTitles:nil];
				[alertView performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
			}
			else {
				[loadouts addObjectsFromArray:[loadoutsList.loadouts sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"thumbsTotal" ascending:NO]]]];
			}
		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (loadouts.count > 0 && ![weakOperation isCancelled]) {
			BCSearchResultViewController *controller = [[BCSearchResultViewController alloc] initWithNibName:@"BCSearchResultViewController" bundle:nil];
			controller.loadouts = loadouts;
			controller.ship = self.ship;
			[self.navigationController pushViewController:controller animated:YES];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return self.tags ? 2 : 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return section == 0 ? 1 : self.tags.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"Cell";
	
	GroupedCell* cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];//[ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
	}
	
    if (indexPath.section == 0) {
		cell.accessoryView = nil;
		if (!self.ship) {
			cell.textLabel.text = NSLocalizedString(@"Select Ship", nil);
			cell.imageView.image = [UIImage imageNamed:@"Icons/icon09_05.png"];
		}
		else {
			cell.textLabel.text = self.ship.typeName;
			cell.imageView.image = [UIImage imageNamed:[self.ship typeSmallImageName]];
		}
	}
	else {
		NSString *tag = [self.tags objectAtIndex:indexPath.row];
		cell.textLabel.text = tag;
		cell.imageView.image = nil;
		cell.accessoryView = [self.selectedTags containsObject:tag] ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]] : nil;
	}
	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 1)
		return NSLocalizedString(@"Tags", nil);
	else
		return nil;
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
		view.collapsImageView.hidden = YES;
		view.titleLabel.text = title;
		return view;
	}
	else
		return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return [self tableView:tableView titleForHeaderInSection:section] ? 22 : 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 0) {
		//fittingItemsViewController.groupsRequest = @"SELECT * FROM invGroups WHERE groupID IN (25,26,27,28,30,31,324,358,380,419,420,463,485,513,540,541,543,547,659,830,831,832,833,834,883,893,894,898,900,902,906,941,963,1022) ORDER BY groupName;";
//		fittingItemsViewController.typesRequest = @"SELECT * FROM invTypes WHERE published=1 AND groupID IN (25,26,27,28,30,31,324,358,380,419,420,463,485,513,540,541,543,547,659,830,831,832,833,834,883,893,894,898,900,902,906,941,963,1022) %@ %@ ORDER BY invTypes.typeName;";
		//fittingItemsViewController.typesRequest = @"SELECT invMetaGroups.metaGroupID, invMetaGroups.metaGroupName, invTypes.* FROM invTypes LEFT JOIN invMetaTypes ON invMetaTypes.typeID=invTypes.typeID LEFT JOIN invMetaGroups ON invMetaTypes.metaGroupID=invMetaGroups.metaGroupID  WHERE invTypes.published=1 AND groupID IN (25,26,27,28,30,31,324,358,380,419,420,463,485,513,540,541,543,547,659,830,831,832,833,834,883,893,894,898,900,902,906,941,963,1022) %@ %@ ORDER BY invTypes.typeName";
		self.fittingItemsViewController.marketGroupID = 4;
		self.fittingItemsViewController.title = NSLocalizedString(@"Ships", nil);
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[self.popoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[self presentModalViewController:self.modalController animated:YES];
	}
	else {
		NSString *tag = [self.tags objectAtIndex:indexPath.row];
		if ([self.selectedTags containsObject:tag])
			[self.selectedTags removeObject:tag];
		else
			[self.selectedTags addObject:tag];
		[tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		[self testInputData];
	}
	return;
}

#pragma mark FittingItemsViewControllerDelegate

- (void) fittingItemsViewController:(FittingItemsViewController*) controller didSelectType:(EVEDBInvType*) type {
	self.ship = type;
	[self testInputData];
	[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.popoverController dismissPopoverAnimated:YES];
	else
		[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Private

- (void) testInputData {
	self.searchButton.enabled = self.ship && self.selectedTags.count > 0;
}

@end