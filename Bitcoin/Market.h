//
//  Market.h
//  Bitcoin
//
//  Created by Rits Plasman on 10-06-11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Market : NSObject <NSCoding> {
    
}

@property (nonatomic, assign) double close;
@property (nonatomic, copy) NSString *symbol;
@property (nonatomic, retain) NSDate *latestTrade;

@end
