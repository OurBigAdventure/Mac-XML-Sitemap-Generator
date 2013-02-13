//
//  OBASitemapViewController.m
//  Sitemap
//
//  Created by Chris Brown on 2/8/13.
//  Copyright (c) 2013 Chris Brown. All rights reserved.
//

#import "OBASitemapViewController.h"
#import "TFHpple.h"

@interface OBASitemapViewController ()

@property (nonatomic) NSMutableDictionary *collectedURLs;
@property (nonatomic) NSMutableArray *visitedURLs;

@end

@implementation OBASitemapViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        self.collectedURLs = [[NSMutableDictionary alloc] initWithCapacity:0];
        self.visitedURLs = [[NSMutableArray alloc] initWithCapacity:0];
    }
    
    return self;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    // Get the keys to the collectedURLs dictionary
    NSArray *keys = [self.collectedURLs allKeys];
    
    // Get the maximum number of links to a page in the dictionary
    int maxLinks = INT_MIN;
    for (NSInteger i = 0; i < [keys count]; i++) {
        int val = [[self.collectedURLs valueForKey:[keys objectAtIndex:i]] intValue];
        if (val > maxLinks) {
            maxLinks = val;
        }
    }
    
    // Get a new ViewCell
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    // Depending on the column, return the value that matches the cell's value
    if ([tableColumn.identifier isEqualToString:@"URLColumn"]) {
        if (keys == nil || [keys count] == 0) {
            cellView.textField.stringValue = @"";
        } else {
            cellView.textField.stringValue = [keys objectAtIndex:row];
        }
        return cellView;
    } else if ([tableColumn.identifier isEqualToString:@"InboundLinks"]) {
        if (keys == nil || [keys count] == 0) {
            cellView.textField.stringValue = @"";
        } else {
            cellView.textField.stringValue = [self.collectedURLs valueForKey:[keys objectAtIndex:row]];
        }
        return cellView;
    } else if ([tableColumn.identifier isEqualToString:@"CalculatedPriority"]) {
        if (keys == nil || [keys count] == 0) {
            cellView.textField.stringValue = @"";
        } else {
            float rating = [[self.collectedURLs valueForKey:[keys objectAtIndex:row]] floatValue];
            cellView.textField.stringValue = [NSString stringWithFormat:@"%0.1f", (rating / maxLinks)];
        }
        return cellView;
    }
    return cellView;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.collectedURLs count];
}

- (IBAction)crawlRequestedURL:(NSTextField *)sender {
    NSLog(@"URL Crawl Requested! URL:%@", sender.stringValue);
    // Verify that a URL is detected
    NSDataDetector *detect = [[NSDataDetector alloc] initWithTypes:(NSTextCheckingTypes)NSTextCheckingTypeLink error:nil];
    NSArray *matches = [detect matchesInString:sender.stringValue options:0 range:NSMakeRange(0, [sender.stringValue length])];
    
    if ([matches count] > 0 && [sender.stringValue hasPrefix:@"http"]) {
        NSLog(@"URL Good");
        if ([sender.stringValue hasSuffix:@"/"]) {
            sender.stringValue = [sender.stringValue substringToIndex:[sender.stringValue length] -1];
        }
        NSURL *providedURL = [NSURL URLWithString:sender.stringValue];
        [self.visitedURLs removeAllObjects];
        [self.collectedURLs removeAllObjects];
        [self parseURL:providedURL];
    } else {
        // Popup Alert saying URL bad
        NSLog(@"URL Bad");
        NSAlert *badURLAlert = [[NSAlert alloc] init];
        [badURLAlert addButtonWithTitle:@"OK"];
        [badURLAlert setMessageText:@"Sorry, Bad URL"];
        [badURLAlert setInformativeText:@"Plese provide the root URL for the site you want to crawl begining with 'http(s)://'"];
        [badURLAlert setAlertStyle:NSWarningAlertStyle];
        [badURLAlert runModal];
        badURLAlert = nil;
    }
}

- (void)parseURL:(NSURL*)URL
{
    NSLog(@"Parsing URL: %@", URL);
    // Check for URL in visited Array
    if ([self.visitedURLs containsObject:URL]) {
        NSLog(@"URL Already Visited...");
        NSLog(@"%@", self.visitedURLs);
        // Add 1 to the count of links to this URL
        NSNumber *linkCount = [NSNumber numberWithInt:([[self.collectedURLs valueForKey:[URL absoluteString]] intValue] + 1)];
        NSLog(@"Updating Link Count... (%@)", linkCount);
        [self.collectedURLs setObject:linkCount forKey:[URL absoluteString]];
        NSLog(@"%@", self.collectedURLs);
        // Done parsing this URL, nothing else to do here...
    } else {
        NSLog(@"New URL...");
        NSData *requestHtmlData = [NSData dataWithContentsOfURL:URL];
        TFHpple *urlParser = [TFHpple hppleWithHTMLData:requestHtmlData];
        
        NSString *requestXpathQueryString = @"//a";
        NSArray *requestNodes = [urlParser searchWithXPathQuery:requestXpathQueryString];
        
        [self.visitedURLs addObject:URL];
        NSLog(@"Added to Visited List...");
        NSLog(@"%@", self.visitedURLs);
        NSLog(@"Looping through discovered URLs...");
        for (TFHppleElement *element in requestNodes) {
            NSLog(@"discovered: %@", [element objectForKey:@"href"]);
            // Filter and Clean format of URL
            NSString *workingURL = [element objectForKey:@"href"];
            if ([workingURL hasPrefix:@"http"]) {
                NSLog(@"Full http link found...");
                // this is a full URL reference, make sure it's local
                NSURL *tempURL = [NSURL URLWithString:workingURL];
                if ([tempURL host] == [URL host]) {
                    // This is a local URL
                } else {
                    // This is a non-local URL
                    // stop following this URL thread
                    continue;
                }
            } else {
                NSLog(@"Relative link found...");
                // this is a relative URL
                if ([workingURL hasPrefix:@"/"]) {
                    // this URL begins with a slash, remove it for consistancy
                    workingURL = [workingURL substringFromIndex:1];
                }
//                NSError *error = NULL;
//                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"../" options:NSRegularExpressionCaseInsensitive error:&error];
//                NSUInteger numberOfMatches = [regex numberOfMatchesInString:workingURL options:0 range:NSMakeRange(0, [workingURL length])];
//                if (numberOfMatches > 0) {
//                    NSLog(@"Reference to upper directory '../' found...");
//                    // found '../', drop same number of folders from incoming URL
//                    NSMutableArray *pathComponents = [[[NSURL URLWithString:workingURL] pathComponents] mutableCopy];
//                    for (NSInteger i = 0; i < numberOfMatches; i++) {
//                        [pathComponents removeLastObject];
//                    }
//                    workingURL = [[pathComponents valueForKey:@"description"] componentsJoinedByString:@""];
//                }
                workingURL = [NSString stringWithFormat:@"%@://%@/%@", [URL scheme], [URL host], workingURL];
                NSLog(@"Completed construction of full URL: %@", workingURL);
            }
//            NSURL *formattedURL = [NSURL URLWithString:workingURL];
            // Verify the URL is of the file types we are looking for (.php, .htm, .html, .asp, .aspx, /)
//            if (!([[formattedURL lastPathComponent] hasSuffix:@".php"] || [[formattedURL lastPathComponent] hasSuffix:@".htm"] || [[formattedURL lastPathComponent] hasSuffix:@".html"] || [[formattedURL lastPathComponent] hasSuffix:@".asp"] || [[formattedURL lastPathComponent] hasSuffix:@".aspx"] || [[formattedURL lastPathComponent] hasSuffix:@"/"])) {
//                // extension does not match what we are interested in
//                NSLog(@"Last Path Component is No Good: %@", [formattedURL lastPathComponent]);
//                continue;
//            }
            NSLog(@"Done filtering new URLs...");
            // Add filtered URL to Dictionary with link count of 1
            NSLog(@"Adding URL to Dictionary...");
            [self.collectedURLs setObject:[NSNumber numberWithInt:1] forKey:workingURL];
            NSLog(@"%@", self.collectedURLs);
            // Reload Table
            [self.crawlTableView reloadData];
            // parse found URLs
            [self parseURL:[NSURL URLWithString:workingURL]];
        }
    }
}

@end
