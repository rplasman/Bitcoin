//
//  RootViewController.h
//  Bitcoin
//
//  Created by Rits Plasman on 10-06-11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UITableViewController {
	BOOL _updating;
}

@property (nonatomic, retain) IBOutlet UIView *titleView;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UILabel *subtitleLabel;

@end
