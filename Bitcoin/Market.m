//
//  Market.m
//  Bitcoin
//
//  Created by Rits Plasman on 10-06-11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Market.h"


@implementation Market

@synthesize close			= _close;
@synthesize symbol			= _symbol;
@synthesize latestTrade		= _latestTrade;

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeDouble:_close forKey:@"close"];
	[aCoder encodeObject:_symbol forKey:@"symbol"];
	[aCoder encodeObject:_latestTrade forKey:@"latestTrade"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	
	if (self) {
		_close = [aDecoder decodeDoubleForKey:@"close"];
		_symbol = [[aDecoder decodeObjectForKey:@"symbol"] copy];
		_latestTrade = [[aDecoder decodeObjectForKey:@"latestTrade"] retain];
	}
	
	return self;
}

@end
