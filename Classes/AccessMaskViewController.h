//
//  AccessMaskViewController.h
//  EVEUniverse
//
//  Created by Shimanski on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EVEOnlineAPI.h"

@class APIKey;
@interface AccessMaskViewController : UITableViewController
@property (nonatomic, strong) APIKey* apiKey;

@end
