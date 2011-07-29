//
//  MarketCellBackgroundView.m
//  Bitcoin
//
//  Created by Rits Plasman on 10-06-11.
//  Copyright 2011 Taplicity. All rights reserved.
//

#import "MarketCellBackgroundView.h"
#import "Market.h"

@interface MarketCellBackgroundView ()

@property (nonatomic, retain) NSDateFormatter *dateFormatter;

- (NSString *)formattedStringFromDate:(NSDate *)date;

@end

@implementation MarketCellBackgroundView

@synthesize market			= _market;
@synthesize dateFormatter	= _dateFormatter;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		
		self.dateFormatter = dateFormatter;
		[dateFormatter release];
    }
    return self;
}

- (void)setMarket:(Market *)market
{
	if (_market == market) {
		//return;
	}
	
	[market retain];
	[_market release];
	_market = market;
	
	[self setNeedsDisplay];
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

- (void)drawRect:(CGRect)rect
{
	[[UIColor whiteColor] set];
	UIRectFill(rect);
	
	if (!_market)
	{
		return;
	}
	
	[[UIColor blackColor] set];
	
	UIFont *symbolFont = [UIFont boldSystemFontOfSize:18];
	[_market.symbol drawAtPoint:CGPointMake(10.0, 6.0) forWidth:280.0 withFont:symbolFont lineBreakMode:UILineBreakModeTailTruncation];
	
	UIFont *dateFont = [UIFont systemFontOfSize:14];
	
	[[UIColor lightGrayColor] set];
	NSString *latestTrade = [self formattedStringFromDate:_market.latestTrade];

	[latestTrade drawAtPoint:CGPointMake(10.0, 30.0) forWidth:280.0 withFont:dateFont lineBreakMode:UILineBreakModeTailTruncation];
	
	NSString *close = [NSString stringWithFormat:@"%.2f", _market.close];
	if (_market.close < _market.previousClose) {
		[[UIColor colorWithRed:0.6 green:0.3 blue:0.3 alpha:1.0] set];
	} else {
		[[UIColor colorWithRed:0.3 green:0.6 blue:0.3 alpha:1.0] set];
	}
	
	UIFont *closeFont = [UIFont boldSystemFontOfSize:20];
	CGSize size = [close sizeWithFont:closeFont];
	[close drawAtPoint:CGPointMake(310.0 - size.width, 14.0) withFont:closeFont];
}


- (void)dealloc
{
	[_market release];
	[_dateFormatter release];
    [super dealloc];
}

@end
