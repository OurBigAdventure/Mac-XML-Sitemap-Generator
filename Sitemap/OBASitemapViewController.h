//
//  OBASitemapViewController.h
//  Sitemap
//
//  Created by Chris Brown on 2/8/13.
//  Copyright (c) 2013 Chris Brown. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OBASitemapData.h"

@interface OBASitemapViewController : NSViewController <NSTextFieldDelegate>

@property (strong) NSMutableArray *URLs;

- (IBAction)crawlRequestedURL:(NSTextField *)sender;

@end
