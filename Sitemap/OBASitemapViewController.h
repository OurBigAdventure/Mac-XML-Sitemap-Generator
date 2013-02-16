//
//  OBASitemapViewController.h
//  Sitemap
//
//  Created by Chris Brown on 2/8/13.
//  Copyright (c) 2013 Chris Brown. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@interface OBASitemapViewController : NSViewController <NSTextFieldDelegate>

@property (strong) NSMutableArray *URLs;
@property (strong) IBOutlet NSTableView *crawlTableView;
@property (strong) IBOutlet NSTextField *crawlRequestTextField;
@property (strong) IBOutlet NSTextField *currentCrawlLabel;

- (IBAction)crawlRequestedURL:(NSTextField *)sender;
- (IBAction)writeXMLSitemapToFile:(NSButton *)sender;
@end
