//
//  OBAAppDelegate.m
//  Sitemap
//
//  Created by Chris Brown on 2/8/13.
//  Copyright (c) 2013 Chris Brown. All rights reserved.
//

#import "OBAAppDelegate.h"
#import "OBASitemapViewController.h"

@interface OBAAppDelegate()
@property (nonatomic, strong) IBOutlet OBASitemapViewController *sitemapViewController;
@end

@implementation OBAAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Create the new view controller
    self.sitemapViewController = [[OBASitemapViewController alloc] initWithNibName:@"OBASitemapViewController" bundle:nil];
    
    // Sample Data
    OBASitemapData *data1 = [[OBASitemapData alloc] initWithURL:@"http://www.ourbigadventure.com" rating:0.3 numLinks:4];
    OBASitemapData *data2 = [[OBASitemapData alloc] initWithURL:@"http://www.ourbigadventure.com/category/At%20Home" rating:0.5 numLinks:2];
    OBASitemapData *data3 = [[OBASitemapData alloc] initWithURL:@"http://www.ourbigadventure.com/category/holidays" rating:0.1 numLinks:2];
    OBASitemapData *data4 = [[OBASitemapData alloc] initWithURL:@"http://www.ourbigadventure.com/category/vacations" rating:0.7 numLinks:7];
    NSMutableArray *URLs = [NSMutableArray arrayWithObjects:data1, data2, data3, data4, nil];
    
    self.sitemapViewController.URLs = URLs;
    
    // Add the view controller to the window's content view
    [self.window.contentView addSubview:self.sitemapViewController.view];
    self.sitemapViewController.view.frame = ((NSView*)self.window.contentView).bounds;
}

@end
