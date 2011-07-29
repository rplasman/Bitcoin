//
//  SettingsViewController.h
//  Bitcoin
//
//  Created by Rits Plasman on 10-06-11.
//  Copyright 2011 Taplicity. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SettingsViewControllerDelegate;

@interface SettingsViewController : UITableViewController {
    
}

@property (nonatomic, assign) id <SettingsViewControllerDelegate> delegate;

@end

@protocol SettingsViewControllerDelegate <NSObject>

- (void)settingsViewControllerDidFinish:(SettingsViewController *)controller;

@end