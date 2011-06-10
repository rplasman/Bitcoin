//
//  RootViewController.m
//  Bitcoin
//
//  Created by Rits Plasman on 10-06-11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RootViewController.h"
#import "JSONKit.h"
#import "Market.h"
#import "GCDAsyncSocket.h"

@interface RootViewController () <GCDAsyncSocketDelegate>

@property (nonatomic, retain) NSMutableData *receivedData;
@property (nonatomic, retain) NSArray *markets;
@property (nonatomic, retain) NSDateFormatter *dateFormatter;
@property (nonatomic, retain) GCDAsyncSocket *asyncSocket;
@property (nonatomic, retain) NSData *delimiterData;

- (void)reloadData;
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (NSString *)formattedStringFromDate:(NSDate *)date;
- (NSString *)marketsPath;
- (void)archiveMarkets;
- (void)unarchiveMarkets;
- (BOOL)shouldReloadData;

@end

@implementation RootViewController

@synthesize receivedData			= _receivedData;
@synthesize markets					= _markets;
@synthesize dateFormatter			= _dateFormatter;
@synthesize asyncSocket				= _asyncSocket;
@synthesize delimiterData			= _delimiterData;

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
	}
	
	return self;
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
	[self archiveMarkets];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	[self archiveMarkets];
}

- (NSString *)marketsPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES); 
    NSString *cacheDirectory = [paths objectAtIndex:0];  
    NSString *path = [cacheDirectory stringByAppendingPathComponent:@"Markets"]; 
	
    return path;
}

- (void)archiveMarkets
{
	NSMutableArray *archivedMarkets = [NSMutableArray array];
	for (Market *market in _markets) {
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:market];
		[archivedMarkets addObject:data];
	}
	[archivedMarkets writeToFile:[self marketsPath] atomically:YES];
}

- (void)unarchiveMarkets
{
	NSArray *archivedMarkets = [NSArray arrayWithContentsOfFile:[self marketsPath]];
	NSMutableArray *markets = [NSMutableArray array];
	for (NSData *data in archivedMarkets) {
		Market *market = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		[markets addObject:market];
	}
	self.markets = markets;
}

- (BOOL)shouldReloadData
{
	NSDate *lastUpdate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastUpdate"];
	NSDate *now = [NSDate date];
	NSTimeInterval timeInterval = [now timeIntervalSinceDate:lastUpdate];
	
	DLog(@"shouldReloadData: %d", lastUpdate == nil || timeInterval > 900.0);
	
	return lastUpdate == nil || timeInterval > 900.0;
}

- (void)refresh
{
	if ([self shouldReloadData]) {
		[self reloadData];
	}
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	if ([self shouldReloadData]) {
		[self reloadData];
	} else {
		[self unarchiveMarkets];
	}
	
	UIBarButtonItem *refreshButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)];
	self.navigationItem.rightBarButtonItem = refreshButtonItem;
	[refreshButtonItem release];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	
	self.dateFormatter = dateFormatter;
	[dateFormatter release];
	
	GCDAsyncSocket *asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	self.asyncSocket = asyncSocket;
	[asyncSocket release];
	
	self.delimiterData = [GCDAsyncSocket ZeroData];
	
	[_asyncSocket connectToHost:@"bitcoincharts.com" onPort:27007 error:nil];
	
	// [self refresh];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	[sock readDataToData:_delimiterData withTimeout:-1.0 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	[sock readDataToData:_delimiterData withTimeout:-1.0 tag:0];
	
	NSString *readString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSRange range = [readString rangeOfString:@"}"];
	if (range.location == NSNotFound || range.length == 0) {
		return;
	}
	
	NSString *JSONString = [readString substringToIndex:range.location + 1];
	NSDictionary *dictionary = [JSONString objectFromJSONString];

	
	NSInteger index;
	Market *market = nil;
	for (index = 0; index < [_markets count]; index++) {
		 Market *tempMarket = [_markets objectAtIndex:index];
		if ([tempMarket.symbol isEqualToString:[dictionary objectForKey:@"symbol"]]) {
			market = tempMarket;
			break;
		}
	}		
	
	if (market == nil) {
		return;
	}
	
	market.latestTrade = [NSDate dateWithTimeIntervalSince1970:[[dictionary objectForKey:@"timestamp"] intValue]];
	market.close = [[dictionary objectForKey:@"price"] doubleValue];
	
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	[self configureCell:cell atIndexPath:indexPath];
	
	NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
	
	[self.tableView beginUpdates];
	[self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationBottom];
	[self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
	[self.tableView endUpdates];
}

- (void)reloadData
{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	NSURL *URL = [NSURL URLWithString:@"http://www.bitcoincharts.com/t/markets.json"];
//	NSURL *URL = [NSURL URLWithString:@"http://www.google.com"];
	NSURLRequest *request = [NSURLRequest requestWithURL:URL];
	[NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	self.receivedData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *receivedString = [[NSString alloc] initWithData:_receivedData encoding:NSUTF8StringEncoding];
//	DLog(@"'%@'", receivedString);
//	NSString *file = [[NSBundle mainBundle] pathForResource:@"Markets" ofType:@"json"];
//	NSString *receivedString = [[NSString alloc] initWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];

	NSArray *marketDictionaries = [receivedString objectFromJSONString];
	[receivedString release];
	
	NSMutableArray *markets = [NSMutableArray array];
	for (NSDictionary *marketDictionary in marketDictionaries)
	{
		Market *market = [[Market alloc] init];
		market.close		= [[marketDictionary objectForKey:@"close"] doubleValue];
		market.symbol		= [marketDictionary objectForKey:@"symbol"];
		market.latestTrade	= [NSDate dateWithTimeIntervalSince1970:[[marketDictionary objectForKey:@"latest_trade"] floatValue]];
		[markets addObject:market];
		[market release];
	}
	
	self.markets = markets;
	
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastUpdate"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[self.tableView reloadData];
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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

/*
 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 */

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_markets count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
    }
	
	[self configureCell:cell atIndexPath:indexPath];

	// Configure the cell.
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	Market *market = [_markets objectAtIndex:indexPath.row];
	cell.textLabel.text = market.symbol;
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f", market.close];
}

- (NSString *)formattedStringFromDate:(NSDate *)date
{
	NSDate *now = [NSDate date];
	NSTimeInterval timeInterval = [now timeIntervalSinceDate:date];
	
	if (timeInterval < 30) {
		return NSLocalizedString(@"just now", @"");
	}
	
	if (timeInterval < 90) {
		return NSLocalizedString(@"1 minute ago", @"");
	}
	
	if (timeInterval < 3600) {
		return [NSString stringWithFormat:NSLocalizedString(@"%.0f minutes ago", @""), round(timeInterval / 60.0)];
	}
	
	if (timeInterval < 5400) {
		return NSLocalizedString(@"1 hour ago", @"");
	}
	
	if (timeInterval < 86400) {
		return [NSString stringWithFormat:NSLocalizedString(@"%.0f hours ago", @""), round(timeInterval / 3600.0)];
	}
	
	return [_dateFormatter stringFromDate:date];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert)
    {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
    // ...
    // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
    [detailViewController release];
	*/
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

- (void)dealloc
{
    [super dealloc];
}

@end
