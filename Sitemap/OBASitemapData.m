//
//  OBASitemapData.m
//  Sitemap
//
//  Created by Chris Brown on 2/8/13.
//  Copyright (c) 2013 Chris Brown. All rights reserved.
//

#import "OBASitemapData.h"

@implementation OBASitemapData

- (id)initWithURL:(NSString*)URL rating:(float)rating numLinks:(NSInteger)numLinks
{
    if ((self = [super init])) {
        self.URL = URL;
        self.rating = rating;
        self.numLinks = numLinks;
    }
    return self;
}

@end
