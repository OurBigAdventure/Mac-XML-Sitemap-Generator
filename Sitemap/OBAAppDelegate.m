//
//  OBAAppDelegate.m
//  Sitemap
//
//  Created by Chris Brown on 2/8/13.
//  Copyright (c) 2013 Chris Brown. All rights reserved.
//

#import "OBAAppDelegate.h"
#include "OBASitemapViewController.h"

@interface OBAAppDelegate()
@property (nonatomic, strong) IBOutlet OBASitemapViewController *sitemapViewController;
@end

@implementation OBAAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Create the new view controller
    self.sitemapViewController = [[OBASitemapViewController alloc] initWithNibName:@"OBASitemapViewController" bundle:nil];
    
    // Add the view controller to the window's content view
    [self.window.contentView addSubview:self.sitemapViewController.view];
    self.sitemapViewController.view.frame = ((NSView*)self.window.contentView).bounds;
}

@end
