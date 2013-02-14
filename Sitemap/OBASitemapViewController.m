//
//  OBASitemapViewController.m
//  Sitemap
//
//  Created by Chris Brown on 2/8/13.
//  Copyright (c) 2013 Chris Brown. All rights reserved.
//

#import "OBASitemapViewController.h"
#import "OBAURLData.h"
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
        int val = [[self.collectedURLs objectForKey:[keys objectAtIndex:i]] incomingLinks];
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
            cellView.textField.stringValue = [NSString stringWithFormat:@"%d", [[self.collectedURLs objectForKey:[keys objectAtIndex:row]] incomingLinks]];
        }
        return cellView;
    } else if ([tableColumn.identifier isEqualToString:@"CalculatedPriority"]) {
        if (keys == nil || [keys count] == 0) {
            cellView.textField.stringValue = @"";
        } else {
            float rating = [[self.collectedURLs objectForKey:[keys objectAtIndex:row]] incomingLinks];
            float priority = rating / maxLinks;
            if (priority < 0.5) {
                priority = priority + 0.2;
            }
            cellView.textField.stringValue = [NSString stringWithFormat:@"%0.1f", priority];
        }
        return cellView;
    }
    return cellView;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.collectedURLs count];
}

- (IBAction)crawlRequestedURL:(NSTextField *)sender {
    // Verify that a URL is detected
    NSDataDetector *detect = [[NSDataDetector alloc] initWithTypes:(NSTextCheckingTypes)NSTextCheckingTypeLink error:nil];
    NSArray *matches = [detect matchesInString:sender.stringValue options:0 range:NSMakeRange(0, [sender.stringValue length])];
    
    if ([matches count] > 0 && [sender.stringValue hasPrefix:@"http"]) {
        // Good URL verified
        if ([sender.stringValue hasSuffix:@"/"]) {
            sender.stringValue = [sender.stringValue substringToIndex:[sender.stringValue length] -1];
        }
        NSURL *providedURL = [NSURL URLWithString:sender.stringValue];
        [self.visitedURLs removeAllObjects];
        [self.collectedURLs removeAllObjects];
        [self parseURL:providedURL];
    } else {
        // Popup Alert saying URL bad
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
    // Check for URL in visited Array
    if ([self.visitedURLs containsObject:URL]) {
        // Add 1 to the count of links to this URL
        [[self.collectedURLs objectForKey:[URL absoluteString]] addToIncomingLinks];
        // Done parsing this URL, nothing else to do here...
    } else {
        NSData *requestHtmlData = [NSData dataWithContentsOfURL:URL];
        TFHpple *urlParser = [TFHpple hppleWithHTMLData:requestHtmlData];
        
        NSString *requestXpathQueryString = @"//a";
        NSArray *requestNodes = [urlParser searchWithXPathQuery:requestXpathQueryString];
        
        [self.visitedURLs addObject:URL];
        for (TFHppleElement *element in requestNodes) {
            // Filter and Clean format of URL
            NSString *workingURL = [element objectForKey:@"href"];
            if ([workingURL hasPrefix:@"http"]) {
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
                // this is a relative URL
                if ([workingURL hasPrefix:@"/"]) {
                    // this URL begins with a slash, remove it for consistancy
                    workingURL = [workingURL substringFromIndex:1];
                }
                NSArray *tempArray = [workingURL componentsSeparatedByString:@"../"];
                int numberOfMatches = [tempArray count] - 1;
                if (numberOfMatches > 0) {
                    // found '../', drop same number of folders from incoming URL
                    NSMutableArray *pathComponents = [[[NSURL URLWithString:workingURL] pathComponents] mutableCopy];
                    for (NSInteger i = 0; i < numberOfMatches; i++) {
                        [pathComponents removeLastObject];
                        if ([[pathComponents lastObject] isEqualToString:@"/"]) {
                            [pathComponents removeLastObject];                            
                        }
                    }
                    workingURL = [[pathComponents valueForKey:@"description"] componentsJoinedByString:@"/"];
                }
                workingURL = [NSString stringWithFormat:@"%@://%@/%@", [URL scheme], [URL host], workingURL];
            }
            
            NSURL *formattedURL = [NSURL URLWithString:workingURL];
            // Verify the URL is of the file types we are looking for (.php, .htm, .html, .asp, .aspx, /)
            if ([[formattedURL lastPathComponent] rangeOfString:@"."].location != NSNotFound) {
                if (!([[formattedURL lastPathComponent] hasSuffix:@".php"] || [[formattedURL lastPathComponent] hasSuffix:@".htm"] || [[formattedURL lastPathComponent] hasSuffix:@".html"] || [[formattedURL lastPathComponent] hasSuffix:@".asp"] || [[formattedURL lastPathComponent] hasSuffix:@".aspx"] || [[formattedURL lastPathComponent] hasSuffix:@"/"])) {
                    // extension does not match what we are interested in
                    continue;
                }
            }

            // Add filtered URL to Dictionary with link count of 1
            if (![self.collectedURLs objectForKey:workingURL]) {
                [self.collectedURLs setObject:[[OBAURLData alloc] init] forKey:workingURL];
            }
            // Reload Table
            [self.crawlTableView reloadData];
            // parse found URLs
            [self parseURL:[NSURL URLWithString:workingURL]];
        }
    }
}

- (IBAction)writeXMLSitemapToFile:(NSButton *)sender
{
    // Get the keys to the collectedURLs dictionary
    NSArray *keys = [self.collectedURLs allKeys];
    
    // Get the maximum number of links to a page in the dictionary
    int maxLinks = INT_MIN;
    for (NSInteger i = 0; i < [keys count]; i++) {
        int val = [[self.collectedURLs objectForKey:[keys objectAtIndex:i]] incomingLinks];
        if (val > maxLinks) {
            maxLinks = val;
        }
    }
    
    //    <?xml version="1.0" encoding="UTF-8"?>
    //
    //    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    //
    //    <url>
    //
    //    <loc>http://www.example.com/</loc>
    //
    //    <lastmod>2005-01-01</lastmod>
    //
    //    <changefreq>monthly</changefreq>
    //
    //    <priority>0.8</priority>
    //
    //    </url>
    //
    //    </urlset>
    NSString *xmlExportString = @"<?xml version='1.0' encoding='UTF-8'?>\n<urlset xmlns='http://www.sitemaps.org/schemas/sitemap/0.9'>\n";
    for (int i = 0; i < [keys count]; i++) {
        xmlExportString = [xmlExportString stringByAppendingString:[NSString stringWithFormat:@"    <url>\n"]];
        xmlExportString = [xmlExportString stringByAppendingString:[NSString stringWithFormat:@"        <loc>%@</loc>\n", [keys objectAtIndex:i]]];
        float rating = [[self.collectedURLs objectForKey:[keys objectAtIndex:i]] incomingLinks];
        float priority = rating / maxLinks;
        if (priority < 0.5) {
            priority = priority + 0.2;
        }
        xmlExportString = [xmlExportString stringByAppendingString:[NSString stringWithFormat:@"        <priority>%0.1f</priority>\n", priority]];
        xmlExportString = [xmlExportString stringByAppendingString:[NSString stringWithFormat:@"    </url>\n"]];
    }
    xmlExportString = [xmlExportString stringByAppendingString:[NSString stringWithFormat:@"</urlset>"]];
    NSError *error = nil;
    [xmlExportString writeToURL:[self get] atomically:YES encoding:NSUTF8StringEncoding error:&error];
//    [xmlExportString writeToFile:@"/Users/chris/Desktop/Sitemap.xml" atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Fail: %@", [error localizedDescription]);
    }
    
}

-(NSURL *)get {
    // thank you abarnert: http://stackoverflow.com/questions/10906822/objective-c-directory-picker-osx-10-7
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    if ([panel runModal] != NSFileHandlingPanelOKButton) return nil;
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [[[panel URLs] lastObject] absoluteString], @"sitemap.xml"]];
}
@end
