//
//  OBASitemapViewController.m
//  Sitemap
//
//  Created by Chris Brown on 2/8/13.
//  Copyright (c) 2013 Chris Brown. All rights reserved.
//

#import "OBASitemapViewController.h"

@interface OBASitemapViewController ()

@end

@implementation OBASitemapViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    // Get a new ViewCell
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    // Depending on the column, return the value that matches the cell's value
    if ([tableColumn.identifier isEqualToString:@"URLColumn"]) {
        OBASitemapData *data = [self.URLs objectAtIndex:row];
        cellView.textField.stringValue = data.URL;
        return cellView;
    } else if ([tableColumn.identifier isEqualToString:@"InboundLinks"]) {
        OBASitemapData *data = [self.URLs objectAtIndex:row];
        cellView.textField.stringValue = [NSString stringWithFormat:@"%ld", (long)data.numLinks];
        return cellView;
    } else if ([tableColumn.identifier isEqualToString:@"CalculatedPriority"]) {
        OBASitemapData *data = [self.URLs objectAtIndex:row];
        cellView.textField.stringValue = [NSString stringWithFormat:@"%0.1f", data.rating];
        return cellView;
    }
    return cellView;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.URLs count];
}

@end
