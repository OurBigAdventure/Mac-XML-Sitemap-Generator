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
    NSLog(@"\n\nParsing: %@", URL);
    // Check for URL in visited Array
    if ([self.visitedURLs containsObject:URL]) {
        NSLog(@"Already Visited, adding to visit count");
        // Add 1 to the count of links to this URL
        [[self.collectedURLs objectForKey:[URL absoluteString]] addToIncomingLinks];
        // Done parsing this URL, nothing else to do here...
    } else {
        NSLog(@"New URL");
        NSData *requestHtmlData = [NSData dataWithContentsOfURL:URL];
        TFHpple *urlParser = [TFHpple hppleWithHTMLData:requestHtmlData];
        
        NSString *requestXpathQueryString = @"//a";
        NSArray *requestNodes = [urlParser searchWithXPathQuery:requestXpathQueryString];
        
        [self.visitedURLs addObject:URL];
        for (TFHppleElement *element in requestNodes) {
            // Filter and Clean format of URL
            NSString *workingURL = [element objectForKey:@"href"];
            NSLog(@"workingURL: %@", workingURL);
            NSURL *tempURL = [NSURL URLWithString:workingURL];
            if ([[tempURL scheme] isEqualToString:@"http"] || [[tempURL scheme] isEqualToString:@"https"]) {
                NSLog(@"This is a Full URL");
                // this is a full URL reference, make sure it's local
                if ([tempURL host] == [URL host]) {
                    // This is a local URL
                    NSLog(@"This is a URL for the domain we are crawling");
                } else {
                    // This is a non-local URL
                    // stop following this URL thread
                    NSLog(@"This is a URL for another domain, skip it");
                    continue;
                }
            } else if ([tempURL scheme] != NULL) {
                NSLog(@"Odd Scheme: %@", [tempURL scheme]);
                // This is a non http or https URL
                // stop following this URL thread
                continue;
			} else if ([[tempURL description] hasPrefix:@"?"]) {
				// check to see if URL has ? as a beginning
				// we can't use pathComponents because it strips query strings
				NSLog(@"This is a relative URL with only a querystring");
				if ([[URL description] rangeOfString:@"?"].location != NSNotFound) {
					// Remove the existing querystring then add this one in its place
					workingURL = [[[URL description] substringToIndex:[[URL description] rangeOfString:@"?"].location] stringByAppendingString:[tempURL description]];
				} else {
					workingURL = [[URL description] stringByAppendingString:[tempURL description]];
				}
            } else {
                NSLog(@"This is a simple relative URL");
                // this is a relative URL
				NSString *queryString;
				if ([[tempURL description] rangeOfString:@"?"].location != NSNotFound) {
					// There is a query string in this relative URL
					// save it out and add it back after we handle the relative structure
					queryString = [[tempURL description] substringFromIndex:[[tempURL description] rangeOfString:@"?"].location];
					NSLog(@"QueryString: %@", queryString);
				}
				NSMutableArray *pathComponents = [[tempURL pathComponents] mutableCopy];
                if (!pathComponents && ![workingURL hasPrefix:@"?"]) {
					// If no pathComponents skip ahead
					//
					// The problem here is that pathComponents strips query strings
					// so check for querystrings as well before skipping ahead
                    continue;
                }
                NSMutableArray *mainPathComponents = [[URL pathComponents] mutableCopy];
                
                // There are four types of relative paths
                // ./           asks for the current directory
                // ../          asks for the directory above the current directory (multiples possible)
                // /            asks for the base URL
                // file.xxx     asks for a file in the current directory
				
                // Filter the relative URL based on the above cases
                NSLog(@"pathComponents: %@", pathComponents);
                if ([[pathComponents objectAtIndex:0] isEqualToString:@"."]) {
                    NSLog(@"./ case");
                    // if the last component of the main path is a file reference, remove it
                    // Verify the URL is of the file types we are looking for (.php, .htm, .html, .asp, .aspx, /)
                    if ([[mainPathComponents lastObject] rangeOfString:@"."].location != NSNotFound) {
                        if (!([[mainPathComponents lastObject] hasSuffix:@".php"] || [[mainPathComponents lastObject] hasSuffix:@".htm"] || [[mainPathComponents lastObject] hasSuffix:@".html"] || [[mainPathComponents lastObject] hasSuffix:@".asp"] || [[mainPathComponents lastObject] hasSuffix:@".aspx"] || [[mainPathComponents lastObject] hasSuffix:@"/"])) {
                            // extension does not match what we are interested in
                            NSLog(@"1. Not the type of URL we wish to log in our sitemap, skip");
                            continue;
                        } else {
                            [mainPathComponents removeLastObject];
                        }
                    }
                    [pathComponents removeObjectAtIndex:0];
                } else if ([[pathComponents objectAtIndex:0] isEqualToString:@".."]) {
                    NSLog(@"../ case");
                    // Because we can have multiple ..'s loop through each component
                    int loopCount = (int)[pathComponents count];
                    for (NSInteger i = 0; i < loopCount; i++) {
                        // rebuild path from URL leaving off the same number of components as workingURL has '..'
                        if ([[pathComponents objectAtIndex:i] isEqualToString:@".."]) {
                            [mainPathComponents removeLastObject];
                        }
                    }
                    for (NSInteger i = loopCount - 1; i >= 0; i--) {
                        if ([[pathComponents objectAtIndex:i] isEqualToString:@".."]) {
                            [pathComponents removeObjectAtIndex:i];
                        }
                    }
                } else if ([[pathComponents objectAtIndex:0] isEqualToString:@"/"]) {
                    NSLog(@"/ case");
                    // remove the empty component
                    [pathComponents removeObjectAtIndex:0];
                    // remove everything back to the root domain
                    [mainPathComponents removeAllObjects];
                } else {
                    NSLog(@"file.xxx case");
					NSLog(@"--queryString: %@", queryString);
                    // remove last object if not '/' to stay in current path
					if (![[mainPathComponents lastObject] isEqualToString:@"/"]) {
						NSLog(@"removing: '%@' from main path", [mainPathComponents lastObject]);
						[mainPathComponents removeLastObject];
					}
                }
				workingURL = [NSString stringWithFormat:@"%@/%@", [[mainPathComponents valueForKey:@"description"] componentsJoinedByString:@"/"], [[pathComponents valueForKey:@"description"] componentsJoinedByString:@"/"]];
                while ([workingURL hasPrefix:@"/"]) {
                    // this URL begins with a slash, remove it for consistancy
                    workingURL = [workingURL substringFromIndex:1];
                }
				
				// Add querystring back in if it exists
				if ([queryString length] > 0) {
					// Check to see if pathComponents is null
					if (!pathComponents) {
						// this is the href='?...' case, add current page back in before querystring
						if (![[mainPathComponents lastObject] isEqualToString:@"/"]) {
							workingURL = [workingURL stringByAppendingString:[mainPathComponents lastObject]];
						}
					}
					workingURL = [workingURL stringByAppendingString:queryString];
				}
				
                // All types of relative path should be cleaned and prepped to match
                // 1. no leading slash
                // 2. only valid folder/file path remaining
                // 3. main URL path cleaned to match relative path's requirements
                
				workingURL = [NSString stringWithFormat:@"%@://%@/%@", [URL scheme], [URL host], workingURL];
            }
            NSLog(@"Final working URL: %@", workingURL);
            
            NSURL *formattedURL = [NSURL URLWithString:workingURL];
            // Verify the URL is of the file types we are looking for (.php, .htm, .html, .asp, .aspx, /)
            if ([[formattedURL lastPathComponent] rangeOfString:@"."].location != NSNotFound && [[formattedURL lastPathComponent] rangeOfString:@":"].location != NSNotFound) {
                if (!([[formattedURL lastPathComponent] hasSuffix:@".php"] || [[formattedURL lastPathComponent] hasSuffix:@".htm"] || [[formattedURL lastPathComponent] hasSuffix:@".html"] || [[formattedURL lastPathComponent] hasSuffix:@".asp"] || [[formattedURL lastPathComponent] hasSuffix:@".aspx"] || [[formattedURL lastPathComponent] hasSuffix:@"/"])) {
                    // extension does not match what we are interested in
                    NSLog(@"Not the type of URL we wish to log in our sitemap, skip");
                    continue;
                }
            }
			
            // Add filtered URL to Dictionary with link count of 1
            if (![self.collectedURLs objectForKey:workingURL]) {
                NSLog(@"Adding to collected URLs");
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
